//  ChallengeManager.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import SwiftUI

// MARK: - Modèles

struct ParticipantProgress: Identifiable, Codable {
    var id: String
    var joinedDate: Date
    var validatedDays: [Date]
    var medals: [UserMedal]
    var currentStreak: Int
}

// MARK: - ChallengeManager

final class ChallengeManager: ObservableObject {

    static let shared = ChallengeManager()

    private let challengeService: ChallengeService

    @Published var currentUser: User?
    @Published var challenges: [Challenge] = []
    @Published var participants: [String: [ParticipantProgress]] = [:]
    @Published var medals: [UserMedal] = []
    @Published var photos: [String: [ChallengePhoto]] = [:]
    @Published var selectedTab: Tabs = .challenge

    private init(challengeService: ChallengeService = ChallengeService.shared) {
        self.challengeService = challengeService
    }

    enum Tabs: Hashable {
        case challenge
        case camera
        case settings
    }

    func saveUser(_ user: User) {
        self.currentUser = user
    }

    func resetUser() {
        self.currentUser = nil
    }

    func loadCurrentUserFromFirestore(completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ Aucun utilisateur connecté")
            completion(false)
            return
        }
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("❌ Erreur Firestore: \(error.localizedDescription)")
                completion(false)
                return
            }

            do {
                if let user = try snapshot?.data(as: User.self) {
                    print("✅ Utilisateur chargé: \(user.name)")
                    self.currentUser = user
                    completion(true)
                } else {
                    print("❌ Document utilisateur introuvable ou vide")
                    completion(false)
                }
            } catch {
                print("❌ Erreur de décodage utilisateur: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    func challengesForCurrentUser() -> [Challenge] {
        guard let uid = currentUser?.id else { return [] }
        return challenges.filter { $0.creatorUID == uid || $0.participantUids.contains(uid) }
    }
    /// Récupère tous les défis présents dans Firestore sans filtrage
    func fetchAllChallengesOnceAsync() async -> [Challenge] {
        let db = Firestore.firestore()

        do {
            let snapshot = try await db.collection("challenges").getDocuments()
            let challenges = try snapshot.documents.map { try $0.data(as: Challenge.self) }
            return challenges
        } catch {
            print("❌ Erreur Firestore dans fetchAllChallengesOnceAsync: \(error)")
            return []
        }
    }

    /// Met à jour un défi dans Firestore et localement dans la liste `challenges`
    func updateChallenge(_ updatedChallenge: Challenge) async {
        guard let id = updatedChallenge.id else {
            print("❌ Challenge ID manquant")
            return
        }

        if let index = challenges.firstIndex(where: { $0.id == id }) {
            challenges[index] = updatedChallenge
        }

        let db = Firestore.firestore()
        do {
            try db.collection("challenges").document(id).setData(from: updatedChallenge) { error in
                if let error = error {
                    print("❌ Firestore updateChallenge erreur: \(error.localizedDescription)")
                } else {
                    print("✅ Firestore challenge mis à jour")
                }
            }
        } catch {
            print("❌ Erreur d'encodage updateChallenge: \(error)")
        }
    }

    /// Ajoute un nouveau défi dans Firestore puis recharge la liste des défis filtrés
    func addNewChallengeToFirestore(_ challenge: Challenge, completion: ((Bool) -> Void)? = nil) {
        ChallengeService.shared.addChallenge(challenge) { error in
            if let error = error {
                print("❌ Erreur création défi: \(error)")
                completion?(false)
                return
            }

            Task {
                await self.fetchAndFilterChallenges()
                DispatchQueue.main.async {
                    completion?(true)
                }
            }
        }
    }

    /// Ajoute une médaille à un utilisateur pour un défi donné (dans le cache local)
    func addMedal(_ medal: UserMedal, to userId: String, for challengeId: String) {
        if var progresses = participants[challengeId],
           let idx = progresses.firstIndex(where: { $0.id == userId }) {
            progresses[idx].medals.append(medal)
            participants[challengeId] = progresses
        }
    }
    /// Met à jour la progression d’un utilisateur pour un jour validé dans un défi
    func updateProgress(for challengeId: String, userId: String, on day: Date) {
        if var progresses = participants[challengeId],
           let idx = progresses.firstIndex(where: { $0.id == userId }) {
            if !progresses[idx].validatedDays.contains(where: { Calendar.current.isDate($0, inSameDayAs: day) }) {
                progresses[idx].validatedDays.append(day)
                participants[challengeId] = progresses
            }
        }
    }
    /// Upload une photo dans Firebase Storage via `ChallengeService`
    func uploadPhotoAsync(image: UIImage, challengeId: String, author: User, description: String? = "") async throws {
        let photo = try await ChallengeService.shared.uploadPhoto(image: image,
                                                                  challengeId: challengeId,
                                                                  author: author,
                                                                  description: description)
        savePhoto(photo, to: challengeId)
    }

    private func savePhoto(_ photo: ChallengePhoto, to challengeId: String) {
        photos[challengeId, default: []].append(photo)
    }




    ///  /// Charge l'utilisateur courant depuis Firestore
    @MainActor
    func loadCurrentUser(completion: @escaping (Bool) -> Void) {
        guard let firebaseUser = Auth.auth().currentUser else {
            print("❌ Aucun utilisateur authentifié")
            self.currentUser = nil
            completion(false)
            return
        }

        let uid = firebaseUser.uid
        let email = firebaseUser.email ?? ""
        let db = Firestore.firestore()

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("❌ Erreur FStore récupération user:", error.localizedDescription)
                completion(false)
                return
            }

            guard let snapshot = snapshot, snapshot.exists,
                  let user = try? snapshot.data(as: User.self) else {
                print("ℹ️ Document utilisateur introuvable, création automatique")
                let newUser = User(id: uid, email: email, name: firebaseUser.displayName ?? "", photoURL: nil, medals: [], joinedChallenges: [])
                self.currentUser = newUser

                do {
                    try db.collection("users").document(uid).setData(from: newUser)
                    print("✅ Utilisateur sauvegardé en base")
                } catch {
                    print("❌ Échec sauvegarde utilisateur:", error.localizedDescription)
                }
                completion(true)
                return
            }

            self.currentUser = user
            print("✅ Utilisateur chargé:", user.name)
            completion(true)
        }
    }

    /// Récupère tous les défis, puis filtre ceux liés à l'utilisateur courant
    @MainActor
    func fetchAndFilterChallenges() async {
        guard let user = currentUser else {
            print("❌ Aucun utilisateur connecté pour filtrer les défis")
            DispatchQueue.main.async { self.challenges = [] }
            return
        }
        let allChallenges = await fetchAllChallengesOnceAsync()

        let filtered = allChallenges.filter { challenge in
            challenge.creatorUID == user.id || challenge.participantUids.contains(user.id ?? "")
        }

        DispatchQueue.main.async {
            self.challenges = filtered
            print("✅ Défis filtrés pour \(user.name):", filtered.map(\.title))
        }
    }


    func loadAllPhotos() {
        for challenge in challenges {
            ChallengeService.shared.fetchPhotos(for: challenge.id ?? "") { [weak self] photos in
                DispatchQueue.main.async {
                    self?.photos[challenge.id ?? ""] = photos
                }
            }
        }
    }

    func updateNotifications(for challenge: Challenge,
                             config: [ChallengeNotification],
                             completion: ((Error?) -> Void)? = nil) {
        guard let id = challenge.id else { return }

        if let idx = self.challenges.firstIndex(where: { $0.id == id }) {
            self.challenges[idx].notificationsConfig = config
        }

        challengeService.updateNotifications(for: challenge, config: config) { error in
            completion?(error)
        }
    }
}
extension ChallengeManager {
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

    /// Supprime une photo dans la sous-collection "photos" du challenge (Firestore + Storage) + met à jour le cache local.
    func deletePhoto(_ photo: ChallengePhoto, completion: @escaping (Bool) -> Void) {
        guard let challengeId = photo.challengeId, let photoId = photo.id else {
            completion(false)
            return
        }
        let db = Firestore.firestore()
        let storage = Storage.storage()
        // 1. Supprimer du Storage d'abord (si URL)
        func removeFromStorage(_ completion: @escaping (Bool) -> Void) {
            if !photo.imageUrl.isEmpty {
                let ref = storage.reference(forURL: photo.imageUrl)
                ref.delete { error in
                    if let error = error {
                        print("Erreur lors de la suppression Storage: \(error)")
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            } else {
                completion(true)
            }
        }
        // 2. Supprimer de Firestore
        removeFromStorage { storageSuccess in
            db.collection("challenges").document(challengeId)
                .collection("photos").document(photoId).delete { err in
                    DispatchQueue.main.async {
                        if let err = err {
                            print("Erreur lors de la suppression Firestore: \(err)")
                            completion(false)
                        } else {
                            // MAJ cache local
                            self.photos[challengeId]?.removeAll { $0.id == photoId }
                            completion(storageSuccess)
                        }
                    }
                }
        }
    }
}
extension ChallengeManager {
    /// Ajoute une photo à la sous-collection "photos" du challenge sur Firestore et met à jour le cache local.
    func addPhoto(to challenge: Challenge, photo: ChallengePhoto, completion: @escaping (Bool) -> Void) {
        guard let challengeId = challenge.id else {
            print("⚠️ addPhoto > challenge.id est nil ! Impossible de créer une sous-collection.")
            completion(false)
            return
        }
        let db = Firestore.firestore()
        let docRef = db.collection("challenges").document(challengeId)
            .collection("photos").document()

        var photoToSave = photo
        photoToSave.id = docRef.documentID

        print("🔹 addPhoto: challengeId = \(challengeId)")
        print("🔹 photoToSave = \(photoToSave)")
        print("🔹 will set docId = \(docRef.documentID)")

        do {
            try docRef.setData(from: photoToSave) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Erreur Firestore addPhoto: \(error)")
                        completion(false)
                    } else {
                        if self.photos[challengeId] != nil {
                            self.photos[challengeId]?.append(photoToSave)
                        } else {
                            self.photos[challengeId] = [photoToSave]
                        }
                        print("✅ Photo bien enregistrée dans Firestore !")
                        completion(true)
                    }
                }
            }
        } catch {
            print("❌ Erreur d'encodage lors de addPhoto: \(error)")
            completion(false)
        }
    }
}
