//
//  ChallengeService.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

enum ChallengeServiceError: Error {
    case invalidImageData(String)
}

protocol ChallengeServiceProtocol {
    // Challenges
    func fetchAllChallenges() async throws -> [Challenge]
    func addChallenge(_ challenge: Challenge) async throws -> Challenge?
    func updateChallenge(_ challenge: Challenge) async throws
    func deleteChallenge(challengeId: String, completion: ((Error?) -> Void)?)

    // Photos
    func uploadPhoto(image: UIImage, challengeId: String, author: User, description: String?) async throws -> ChallengePhoto
    func fetchPhotos(for challengeId: String) async throws -> [ChallengePhoto]
    func listenToPhoto(challengeId: String, photoId: String, onUpdate: @escaping (ChallengePhoto?) -> Void) -> ListenerRegistration
    func listenToComments(challengeId: String, photoId: String, onUpdate: @escaping ([PhotoCommentModel]) -> Void) -> ListenerRegistration

    // Reward flow
    func addParticipant(to challengeId: String, progress: ParticipantProgress, completion: ((Error?) -> Void)?)
    func fetchParticipants(for challengeId: String, completion: @escaping ([ParticipantProgress]) -> Void)
    func updateProgress(for challengeId: String, progress: ParticipantProgress, completion: ((Error?) -> Void)?)
    func setUserProgress(userId: String, challengeId: String, progress: ParticipantProgress) throws
    func fetchProgress(challengeId: String, userId: String) async throws -> ParticipantProgress?

    // Notifications
    func updateNotifications(for challenge: Challenge, config: [ChallengeNotification], completion: ((Error?) -> Void)?)
}

final class ChallengeService: ChallengeServiceProtocol {
    static let shared = ChallengeService()

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let collection = "challenges"

    private init() {}
}

// MARK: - Challenges
extension ChallengeService {
    /// Récupère tous les défis présents dans Firestore sans filtrage
    func fetchAllChallenges() async throws -> [Challenge] {
        do {
            let snapshot = try await db.collection("challenges").getDocuments()
            let challenges = try snapshot.documents.map { try $0.data(as: Challenge.self) }
            return challenges
        } catch {
            print("❌ Erreur Firestore dans fetchAllChallengesOnceAsync: \(error)")
            return []
        }
    }

    func addChallenge(_ challenge: Challenge) async throws -> Challenge? {
        do {
            let docRef = try db.collection(collection).addDocument(from: challenge)
            let snapshot = try await docRef.getDocument()
            let createdChallenge = try? snapshot.data(as: Challenge.self)

            return createdChallenge
        } catch {
            print("Error creating challenge into database")
            return nil
        }
    }

    func updateChallenge(_ challenge: Challenge) async throws {
        guard let challengeId = challenge.id else {
            print("❌ Challenge ID manquant")
            return
        }

        do {
            try db.collection("challenges").document(challengeId).setData(from: challenge) { error in
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

    func deleteChallenge(challengeId: String, completion: ((Error?) -> Void)? = nil) {
        let challengeRef = db.collection(collection).document(challengeId)

        // 1. Supprime les sous-collections (photos + participants)
        let batch = db.batch()

        // a. Supprime toutes les photos (et éventuellement Storage si besoin)
        challengeRef.collection("photos").getDocuments { photoSnap, error in
            if let docs = photoSnap?.documents {
                for doc in docs {
                    batch.deleteDocument(doc.reference)
                    // Optionnel : supprimer la photo dans Storage
                    if let photo = try? doc.data(as: ChallengePhoto.self) {
                        let path = URL(string: photo.imageUrl)?.path
                        if let path = path {
                            let storageRef = self.storage.reference(withPath: path)
                            storageRef.delete { _ in }
                        }
                    }
                }
            }

            // b. Supprime tous les participants
            challengeRef.collection("participants").getDocuments { partSnap, error in
                if let docs = partSnap?.documents {
                    for doc in docs {
                        batch.deleteDocument(doc.reference)
                    }
                }

                // c. Supprime le challenge lui-même
                batch.deleteDocument(challengeRef)

                // d. Exécute le batch
                batch.commit { error in
                    completion?(error)
                }
            }
        }
    }
}

// MARK: - Photos
extension ChallengeService {
    func uploadPhoto(image: UIImage, challengeId: String, author: User, description: String?) async throws -> ChallengePhoto {
        let resizedImage = image.resized(toMaxWidth: 720)

        guard let data = resizedImage.jpegData(compressionQuality: 0.6) else {
            throw ChallengeServiceError.invalidImageData("Invalid image data")
        }

        let fileName = "\(UUID().uuidString).jpg"
        let ref = storage.reference().child("photos/\(challengeId)/\(author.id ?? "unknown")/\(fileName)")

        // Upload image to Storage
        _ = try await ref.putDataAsync(data, metadata: nil)

        // Get download URL
        let url = try await ref.downloadURL()

        // Create photo object
        let photo = ChallengePhoto(challengeId: challengeId,
                                   authorUid: author.id ?? "",
                                   authorName: author.name,
                                   imageUrl: url.absoluteString,
                                   description: description,
                                   date: Date(),
                                   createdAt: Date())

        // Save in Firestore
        try savePhoto(photo, challengeId: challengeId)

        return photo
    }

    func fetchPhotos(for challengeId: String) async throws -> [ChallengePhoto] {
        let allPhotos = try await db.collection(collection).document(challengeId).collection("photos").getDocuments()

        return allPhotos.documents.compactMap { try? $0.data(as: ChallengePhoto.self) }
    }

    // Privates

    private func savePhoto(_ photo: ChallengePhoto, challengeId: String) throws {
        let docRef = db.collection(collection).document(challengeId).collection("photos").document()
        var photoToSave = photo
        photoToSave.id = docRef.documentID
        try docRef.setData(from: photoToSave)
    }
}

// MARK: - Reward flow
extension ChallengeService {
    func addParticipant(to challengeId: String, progress: ParticipantProgress, completion: ((Error?) -> Void)? = nil) {
        let ref = db.collection(collection).document(challengeId).collection("participants").document(progress.id)
        do {
            try ref.setData(from: progress) { error in
                completion?(error)
            }
        } catch {
            completion?(error)
        }
    }

    func fetchParticipants(for challengeId: String, completion: @escaping ([ParticipantProgress]) -> Void) {
        db.collection(collection).document(challengeId).collection("participants")
            .addSnapshotListener { snapshot, error in
                let progresses = snapshot?.documents.compactMap { try? $0.data(as: ParticipantProgress.self) } ?? []
                completion(progresses)
            }
    }

    func updateProgress(for challengeId: String, progress: ParticipantProgress, completion: ((Error?) -> Void)? = nil) {
        let ref = db.collection(collection).document(challengeId).collection("participants").document(progress.id)
        do {
            try ref.setData(from: progress) { error in
                completion?(error)
            }
        } catch {
            completion?(error)
        }
    }

    // TODO: Utile ?
    //    func addMedal(for challengeId: String, userId: String, medal: UserMedal, completion: ((Error?) -> Void)? = nil) {
    //        let ref = db.collection(collection).document(challengeId).collection("participants").document(userId)
    //        ref.updateData([
    //            "medals": FieldValue.arrayUnion([try! Firestore.Encoder().encode(medal)])
    //        ]) { error in
    //            completion?(error)
    //        }
    //    }

    func setUserProgress(userId: String, challengeId: String, progress: ParticipantProgress) throws {
        return try db
            .collection("challenges")
            .document(challengeId)
            .collection("participants")
            .document(userId)
            .setData(from: progress)
    }

    func fetchProgress(challengeId: String, userId: String) async throws -> ParticipantProgress? {
        let snapshot = try await db
            .collection("challenges")
            .document(challengeId)
            .collection("participants")
            .document(userId)
            .getDocument()

        guard let progress = try? snapshot.data(as: ParticipantProgress.self) else {
            print("⚠️ Pas de progression trouvée pour \(userId)")
            return nil
        }

        print("📊 Progression chargée: validatedDays = \(progress.validatedDays.map { $0.description }), currentStreak = \(progress.currentStreak)")
        return progress
    }
}

// MARK: - Notifications
extension ChallengeService {
    func updateNotifications(for challenge: Challenge,
                             config: [ChallengeNotification],
                             completion: ((Error?) -> Void)? = nil) {
        // Convertir explicitement les dates en timestamps
        let firestoreConfig = config.map { notif in
            return [
                "dayIndex": notif.dayIndex,
                "times": notif.times.map { Timestamp(date: $0) }
            ] as [String : Any]
        }

        db.collection("challenges").document(challenge.id ?? "").updateData([
            "notificationsConfig": firestoreConfig
        ]) { error in
            completion?(error)
        }
    }
}

extension UIImage {
    func resized(toMaxWidth width: CGFloat) -> UIImage {
        let aspectRatio = size.height / size.width
        let newSize = CGSize(width: width, height: width * aspectRatio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Like/Unlike Photo
extension ChallengeService {
    func likePhoto(challengeId: String, photoId: String, userId: String, completion: ((Error?) -> Void)? = nil) {
        let ref = db.collection(collection)
            .document(challengeId)
            .collection("photos")
            .document(photoId)

        ref.updateData([
            "likes": FieldValue.arrayUnion([userId])
        ]) { error in
            completion?(error)
        }
    }

    func unlikePhoto(challengeId: String, photoId: String, userId: String, completion: ((Error?) -> Void)? = nil) {
        let ref = db.collection(collection)
            .document(challengeId)
            .collection("photos")
            .document(photoId)

        ref.updateData([
            "likes": FieldValue.arrayRemove([userId])
        ]) { error in
            completion?(error)
        }
    }

    func listenToPhotoRealtime(challengeId: String, photoId: String, completion: @escaping (ChallengePhoto?) -> Void) -> ListenerRegistration {
        let ref = db.collection(collection).document(challengeId).collection("photos").document(photoId)

        return ref.addSnapshotListener { doc, _ in
            let photo = try? doc?.data(as: ChallengePhoto.self)
            completion(photo)
        }
    }
}


// MARK: - Comments

extension ChallengeService {
    func addComment(photoId: String,
                    content: String,
                    challengeId: String,
                    userId: String,
                    userName: String,
                    completion: ((Error?) -> Void)? = nil) {
        let commentData: [String: Any] = ["userId": userId,
                                          "userName": userName,
                                          "content": content,
                                          "timestamp": Timestamp(date: Date())]

        db.collection("challenges")
            .document(challengeId)
            .collection("photos")
            .document(photoId)
            .collection("comments")
            .addDocument(data: commentData) { error in
                completion?(error)
            }
    }

    func listenToComments(challengeId: String, photoId: String, onUpdate: @escaping ([PhotoCommentModel]) -> Void) -> ListenerRegistration {
        db.collection("challenges")
            .document(challengeId)
            .collection("photos")
            .document(photoId)
            .collection("comments")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return onUpdate([]) }

                let comments = documents.compactMap { try? $0.data(as: PhotoCommentModel.self) }
                onUpdate(comments)
            }
    }

    func listenToPhoto(challengeId: String, photoId: String, onUpdate: @escaping (ChallengePhoto?) -> Void) -> ListenerRegistration {
        db.collection("challenges")
            .document(challengeId)
            .collection("photos")
            .document(photoId)
            .addSnapshotListener { snapshot, error in
                guard let updatedPhoto = try? snapshot?.data(as: ChallengePhoto.self) else { return onUpdate(nil) }

                onUpdate(updatedPhoto)
            }
    }
}
