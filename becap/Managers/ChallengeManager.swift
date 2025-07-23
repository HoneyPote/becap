//
//  ChallengeManager.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

// MARK: - Modèles

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var name: String
    var photoURL: String?
    var medals: [UserMedal]?
    var joinedChallenges: [String]?
}

struct UserMedal: Codable, Identifiable {
    var id: String { name }
    let name: String
    let description: String
    let iconName: String
    let achievedDate: Date
}

struct Challenge: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var duration: Int
    var startDate: Date
    var creatorUID: String
    var participantUids: [String]
    var status: String // "active", "finished"
    var notificationsConfig: [ChallengeNotification]?

    // Hashable synthétique via les propriétés, mais tu peux aussi customiser si besoin :
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
    }

    static func ==(lhs: Challenge, rhs: Challenge) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}

struct ChallengeNotification: Codable {
    var dayIndex: Int
    var times: [Date] // Format "HH:mm" ou utiliser Date si tu préfères
}

struct ParticipantProgress: Identifiable, Codable {
    var id: String // user UID
    var joinedDate: Date
    var validatedDays: [Date]
    var medals: [UserMedal]
    var currentStreak: Int
}

struct ChallengePhoto: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var challengeId: String?             // ID du défi (parent)
    var authorUid: String                // UID Firebase de l'auteur
    var authorName: String               // Nom ou prénom affiché
    var imageUrl: String                 // URL Cloud Storage de la photo
    var description: String?             // Description optionnelle (légende)
    var date: Date                       // Date de prise ou de soumission
    var createdAt: Date                  // Date de création Firestore (souvent == date)

    // Pour Hashable automatique
    static func == (lhs: ChallengePhoto, rhs: ChallengePhoto) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
// MARK: - ChallengeManager

final class ChallengeManager: ObservableObject {
    static let shared = ChallengeManager()

    @Published var currentUser: User?
    @Published var challenges: [Challenge] = []
    @Published var participants: [String: [ParticipantProgress]] = [:] // challengeId -> [progress]
    @Published var medals: [UserMedal] = []
    @Published var photos: [String: [ChallengePhoto]] = [:] // challengeId -> [photo]

    private init() {}

    // MARK: - User

    func saveUser(_ user: User) {
        self.currentUser = user
    }

    func resetUser() {
        self.currentUser = nil
    }

    // MARK: - Challenge CRUD (Firestore à implémenter dans un Service !)

    func addChallenge(_ challenge: Challenge) {
        self.challenges.append(challenge)
    }

    func joinChallenge(_ challenge: Challenge, for user: User) {
        // À compléter selon logique Firestore
    }

    // MARK: - Médailles

    func addMedal(_ medal: UserMedal, to userId: String, for challengeId: String) {
        // Ajoute la médaille dans participants[challengeId], puis mets à jour Firestore
        if var progresses = participants[challengeId],
           let idx = progresses.firstIndex(where: { $0.id == userId }) {
            progresses[idx].medals.append(medal)
            participants[challengeId] = progresses
        }
    }

    // MARK: - Progression

    func updateProgress(for challengeId: String, userId: String, on day: Date) {
        // Ajoute le jour validé dans la progression
        if var progresses = participants[challengeId],
           let idx = progresses.firstIndex(where: { $0.id == userId }) {
            if !progresses[idx].validatedDays.contains(where: { Calendar.current.isDate($0, inSameDayAs: day) }) {
                progresses[idx].validatedDays.append(day)
                participants[challengeId] = progresses
            }
        }
    }

    // MARK: - Photos
    func uploadPhotoAsync(image: UIImage, challengeId: String, author: User, description: String? = "") async throws {
        try await ChallengeService.shared.uploadPhoto(image: image, challengeId: challengeId, author: author, description: description)
    }

    func savePhoto(_ photo: ChallengePhoto, to challengeId: String) {
        photos[challengeId, default: []].append(photo)
    }

    func loadChallenges() {
        ChallengeService.shared.fetchChallenges { [weak self] challenges in
            DispatchQueue.main.async {
                self?.challenges = challenges
            }
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

    func updateNotifications(for challenge: Challenge, config: [ChallengeNotification]) {
        guard let id = challenge.id else { return }

        // mise à jour locale (correcte)
        if let idx = self.challenges.firstIndex(where: { $0.id == id }) {
            self.challenges[idx].notificationsConfig = config
        }

        // mise à jour Firestore (fixée)
        let db = Firestore.firestore()

        // Convertir explicitement les dates en timestamps
        let firestoreConfig = config.map { notif in
            return [
                "dayIndex": notif.dayIndex,
                "times": notif.times.map { Timestamp(date: $0) }
            ] as [String : Any]
        }

        db.collection("challenges").document(id).updateData([
            "notificationsConfig": firestoreConfig
        ]) { error in
            if let error = error {
                print("Erreur mise à jour Firestore:", error.localizedDescription)
            } else {
                print("✅ Firestore config sauvegardée")
            }
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
