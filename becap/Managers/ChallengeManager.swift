//  ChallengeManager.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

enum Tabs: Hashable {
    case challenge
    case camera
    case settings
}

protocol ChallengeManagerProtocol {
    var currentUser: User? { get }
    var challenges: [Challenge] { get }
    var photos: [String: [ChallengePhoto]] { get }

    // Challenge
    func createChallenge(_ challenge: Challenge) async throws -> Challenge?
    func fetchAllChallenges() async throws -> [Challenge]
    func fetchAndFilterChallenges() async throws
    func deleteChallenge(_ challenge: Challenge, completion: @escaping (Bool) -> Void)
    func joinChallenge(_ challenge: Challenge, userId: String) async throws

    // Photos
    func uploadPhotoAsync(image: UIImage, challengeId: String, author: User, description: String?) async throws
    func loadPhotos(from challengeId: String) async throws -> [ChallengePhoto]
    func deletePhotos(_ photosToDelete: [ChallengePhoto], challengeId: String) async throws

    // Reward flow
    func createNewParticipantProgress(userId: String, challengeId: String) async throws
    func updateParticipantProgress(for challengeId: String, userId: String, date: Date) async throws
    func assignCreationMedalsToUser(_ userId: String) async

    // Notifications
    func updateNotifications(for challenge: Challenge, config: [ChallengeNotification], completion: ((Error?) -> Void)?)
}

class ChallengeManager: ChallengeManagerProtocol, ObservableObject {
    static let shared = ChallengeManager()

    @Published private(set) var currentUser: User?
    @Published private(set) var challenges: [Challenge] = []
    @Published private(set) var photos: [String: [ChallengePhoto]] = [:]

//    @Published var participants: [String: [ParticipantProgress]] = [:] // TODO: Utile ?
//    @Published var medals: [UserMedal] = [] // TODO: Utile ?
//    @Published var selectedTab: Tabs = .challenge // TODO: Utile ?

    private var cancellables = Set<AnyCancellable>()

    private let challengeService: ChallengeService
    private let userManager: UserManager
    private let accountManager: AccountManager
    private let rewardService: RewardService
    private let alertManager: GlobalAlertManager

    init(userManager: UserManager = UserManager.shared,
         challengeService: ChallengeService = ChallengeService.shared,
         accountManager: AccountManager = AccountManager(),
         rewardService: RewardService = RewardService.shared,
         alertManager: GlobalAlertManager = GlobalAlertManager.shared) {
        self.userManager = userManager
        self.challengeService = challengeService
        self.accountManager = accountManager
        self.rewardService = rewardService
        self.alertManager = alertManager

        observeCurrentUser()
    }
}

// MARK: - Challenges
extension ChallengeManager {
    func createChallenge(_ challenge: Challenge) async throws -> Challenge? {
        do {
            let newChallenge = try await challengeService.addChallenge(challenge)
            try await self.fetchAndFilterChallenges()

            return newChallenge
        }
    }

    /// Récupère tous les défis présents dans Firestore sans filtrage
    func fetchAllChallenges() async throws -> [Challenge] {
        return try await challengeService.fetchAllChallenges()
    }

    /// Récupère tous les défis, puis filtre ceux liés à l'utilisateur courant
    func fetchAndFilterChallenges() async throws {
        guard let user = currentUser, let userId = user.id else { return }

        let filtered = try await fetchAllChallenges().filter { challenge in
            challenge.creatorUID == userId || challenge.participantUids.contains(userId)
        }

        await MainActor.run {
            self.challenges = filtered
            print("✅ Défis filtrés pour \(user.name):", filtered.map(\.title))
        }
    }

    // TODO: Lier proprement au service
    /// Supprime un challenge (et toutes ses photos associées) côté Firestore & Storage
    func deleteChallenge(_ challenge: Challenge, completion: @escaping (Bool) -> Void) {
        guard let challengeId = challenge.id else {
            completion(false)
            return
        }
        let db = Firestore.firestore()
        let storage = Storage.storage()
        let group = DispatchGroup()
        var overallSuccess = true

        // 1. Supprimer toutes les photos du challenge dans Storage
        let photosToDelete = self.photos[challengeId] ?? []
        for photo in photosToDelete {
            group.enter()
            let ref = storage.reference(forURL: photo.imageUrl)
            ref.delete { error in
                if let error = error {
                    print("Erreur lors de la suppression d’une photo Storage: \(error)")
                    overallSuccess = false
                }
                group.leave()
            }
        }

        // 2. Supprimer toutes les photos du challenge dans Firestore (collection "photos" du challenge)
        group.enter()
        db.collection("challenges").document(challengeId).collection("photos")
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    let deleteGroup = DispatchGroup()
                    for doc in docs {
                        deleteGroup.enter()
                        doc.reference.delete { err in
                            if let err = err {
                                print("Erreur lors de la suppression d’une photo Firestore: \(err)")
                                overallSuccess = false
                            }
                            deleteGroup.leave()
                        }
                    }
                    deleteGroup.notify(queue: .main) {
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }

        // 3. Supprimer le document Challenge principal
        group.enter()
        db.collection("challenges").document(challengeId).delete { err in
            if let err = err {
                print("Erreur lors de la suppression du challenge: \(err)")
                overallSuccess = false
            }
            group.leave()
        }

        // 4. Finaliser la suppression
        group.notify(queue: .main) {
            // Mets à jour le cache local
            self.challenges.removeAll { $0.id == challengeId }
            self.photos[challengeId] = nil
            completion(overallSuccess)
        }
    }

    func joinChallenge(_ challenge: Challenge, userId: String) async throws {
        guard let challengeId = challenge.id else { return }

        try await updateChallenge(challenge)
        try await createNewParticipantProgress(userId: userId, challengeId: challengeId)
    }

    // Challenges - Privates

    private func updateChallenge(_ challenge: Challenge) async throws {
        guard let challengeId = challenge.id else {
            print("❌ Challenge ID manquant")
            return
        }

        try await challengeService.updateChallenge(challenge)
        try await fetchAndFilterChallenges()

        await MainActor.run {
            if let index = challenges.firstIndex(where: { $0.id == challengeId }) {
                challenges[index] = challenge
            }
        }
    }
}

// MARK: - Photos
extension ChallengeManager {
    /// Upload une photo dans Firebase Storage via `ChallengeService`
    func uploadPhotoAsync(image: UIImage, challengeId: String, author: User, description: String? = "") async throws {
        let photo = try await challengeService.uploadPhoto(image: image,
                                                                  challengeId: challengeId,
                                                                  author: author,
                                                                  description: description)
        await MainActor.run {
            savePhoto(photo, to: challengeId)
        }
    }

    func loadPhotos(from challengeId: String) async throws -> [ChallengePhoto] {
        return try await challengeService.fetchPhotos(for: challengeId)
    }

    /// Supprime une photo dans la sous-collection "photos" du challenge (Firestore + Storage) + met à jour le cache local.
    // TODO: Ne plus passer challengeId en paramètre et récupérer cette valeur à travers photo.challengeId lorsque toutes les photos auront un challengeId assigné
    // TODO: Lier proprement au service
    func deletePhotos(_ photosToDelete: [ChallengePhoto], challengeId: String) async throws {
        let db = Firestore.firestore()
        let storage = Storage.storage()

        for photo in photosToDelete {
            guard let photoId = photo.id else {
                throw NSError(domain: "Invalid photo data", code: 400)
            }

            // 1. Supprimer du Storage
            if !photo.imageUrl.isEmpty {
                let ref = storage.reference(forURL: photo.imageUrl)
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    ref.delete { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
            }

            // 2. Supprimer de Firestore
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                db.collection("challenges").document(challengeId)
                    .collection("photos").document(photoId)
                    .delete { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
            }

            // 3. Mettre à jour le cache local
            self.photos[challengeId]?.removeAll { $0.id == photoId }
        }
    }

    // Photos - Privates

    private func savePhoto(_ photo: ChallengePhoto, to challengeId: String) {
        photos[challengeId, default: []].append(photo)
    }
}

// MARK: - Reward flow
extension ChallengeManager {
    func createNewParticipantProgress(userId: String, challengeId: String) async throws {
        let userProgress = ParticipantProgress(id: userId,
                                               joinedDate: Date(),
                                               validatedDays: [],
                                               medals: [],
                                               currentStreak: 0)

        try setUserProgress(userId: userId, challengeId: challengeId, progress: userProgress)
    }

    func updateParticipantProgress(for challengeId: String, userId: String, date: Date) async throws {
        do {
            print("📥 updateProgress lancé pour userId=\(userId), challengeId=\(challengeId)")
            guard var progress = try await fetchProgress(challengeId: challengeId, userId: userId) else { return }

            guard shouldAppendDay(progress: progress, day: date) else {
                print("🔁 Journée déjà validée pour \(date)")
                return
            }

            progress.validatedDays.append(date)
            progress.currentStreak = calculateStreak(from: progress.validatedDays)
            print("✅ Nouvelle journée ajoutée. Streak actuel: \(progress.currentStreak)")

            let newMedals = detectNewMedals(from: progress, challengeId: challengeId)
            progress.medals.append(contentsOf: newMedals)

            await rewardService.persistProgress(progress, for: challengeId)
            await rewardService.addMedals(to: userId, medals: newMedals)

            _ = try await accountManager.updateCurrentUser(with: userId)

            for medal in newMedals {
                await MainActor.run {
                    alertManager.show(medal: medal, challengeId: challengeId)
                    triggerLocalNotification(for: medal)
                }
            }
        } catch {
            print("❌ updateProgress > Erreur fetch: \(error)")
        }
    }

    func assignCreationMedalsToUser(_ userId: String) async {
        let createdCount = challenges.filter { $0.creatorUID == userId }.count
        await rewardService.assignCreationMedals(to: userId, createdCount: createdCount)
    }

    // Reward flow - Privates

    private func setUserProgress(userId: String, challengeId: String, progress: ParticipantProgress) throws {
        return try challengeService.setUserProgress(userId: userId, challengeId: challengeId, progress: progress)
    }

    private func fetchProgress(challengeId: String, userId: String) async throws -> ParticipantProgress? {
        return try await challengeService.fetchProgress(challengeId: challengeId, userId: userId)
    }

    private func shouldAppendDay(progress: ParticipantProgress, day: Date) -> Bool {
        !progress.validatedDays.contains { Calendar.current.isDate($0, inSameDayAs: day) }
    }

    private func detectNewMedals(from progress: ParticipantProgress, challengeId: String) -> [UserMedal] {
        let sortedCount = progress.validatedDays.count
        var medals: [UserMedal] = []

        if sortedCount == 1 && !progress.medals.contains(where: { $0.name == "🟡 Premier jour" }) {
            print("🥇 Ajout médaille: Premier jour")
            medals.append(UserMedal(name: "🟡 Premier jour",
                                    description: "Première validation !",
                                    iconName: "circle.fill",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak == 3 && !progress.medals.contains(where: { $0.name == "🔥 3 jours" }) {
            print("🥈 Ajout médaille: 3 jours")
            medals.append(UserMedal(name: "🔥 3 jours",
                                    description: "3 jours validés d'affilée",
                                    iconName: "flame",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak == 7 && !progress.medals.contains(where: { $0.name == "🔥 7 jours" }) {
            medals.append(UserMedal(name: "🔥 7 jours",
                                    description: "7 jours validés d'affilée",
                                    iconName: "flame.fill",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak == 8 && !progress.medals.contains(where: { $0.name == "🔥 8 jours" }) {
            medals.append(UserMedal(name: "🔥 8 jours",
                                    description: "8 jours validés d'affilée",
                                    iconName: "flame.fill",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak == 14 && !progress.medals.contains(where: { $0.name == "🧨 14 jours" }) {
            medals.append(UserMedal(name: "🧨 14 jours",
                                    description: "14 jours de suite !",
                                    iconName: "burst.fill",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if let challenge = challenges.first(where: { $0.id == challengeId }),
           sortedCount >= challenge.duration,
           !progress.medals.contains(where: { $0.name == "🏁 Terminé" }) {
            medals.append(UserMedal(name: "🏁 Terminé",
                                    description: "Défi complété",
                                    iconName: "checkmark.seal",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        return medals
    }

    private func triggerLocalNotification(for medal: UserMedal) {
        let content = UNMutableNotificationContent()

        content.title = "🎖️ Nouvelle médaille débloquée!"
        content.body = "\(medal.name): \(medal.description)"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func calculateStreak(from dates: [Date]) -> Int {
        let sorted = dates.sorted(by: >)
        var streak = 0

        for date in sorted {
            let expectedDate = Calendar.current.date(byAdding: .day, value: -streak, to: Date()) ?? date

            if Calendar.current.isDate(date, inSameDayAs: expectedDate) {
                streak += 1
            } else {
                break
            }
        }
        print("🔢 Calcul streak depuis:", dates)

        return streak
    }

    // TODO: Utile ?
    /// Ajoute une médaille à un utilisateur pour un défi donné (dans le cache local)
    //    func addMedal(_ medal: UserMedal, to userId: String, for challengeId: String) {
    //        if var progresses = participants[challengeId],
    //           let idx = progresses.firstIndex(where: { $0.id == userId }) {
    //            progresses[idx].medals.append(medal)
    //            participants[challengeId] = progresses
    //        }
    //    }
}

// MARK: - Notifications
extension ChallengeManager {
    func updateNotifications(for challenge: Challenge,
                             config: [ChallengeNotification],
                             completion: ((Error?) -> Void)? = nil) {
        guard let challengeId = challenge.id else { return }

        if let idx = self.challenges.firstIndex(where: { $0.id == challengeId }) {
            self.challenges[idx].notificationsConfig = config
        }

        challengeService.updateNotifications(for: challenge, config: config) { error in
            completion?(error)
        }
    }
}

// MARK: - Observers
extension ChallengeManager {
    private func observeCurrentUser() {
        userManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentUser in
                self?.currentUser = currentUser
            }
            .store(in: &cancellables)
    }
}
