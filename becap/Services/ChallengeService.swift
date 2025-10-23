//
//  ChallengeService.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

enum ChallengeServiceError: Error {
    case invalidImageData(String)
}

protocol ChallengeServiceProtocol {
    // Challenges
    func fetchAllChallenges() async throws -> [Challenge]
    func addChallenge(_ challenge: Challenge) async throws -> Challenge?
    func updateChallenge(_ challenge: Challenge) async throws
    func deleteChallenge(challengeId: String) async throws

    // Photos
    func uploadPhoto(image: UIImage, challengeId: String, author: User, description: String?) async throws -> ChallengePhoto
    func fetchPhotos(for challengeId: String) async throws -> [ChallengePhoto]
    func listenToPhoto(challengeId: String, photoId: String, onUpdate: @escaping (ChallengePhoto?) -> Void)
    func listenToComments(challengeId: String, photoId: String, onUpdate: @escaping ([PhotoCommentModel]) -> Void)

    // Reward flow
    func addParticipant(to challengeId: String, progress: ParticipantProgress, completion: ((Error?) -> Void)?)
    func fetchParticipants(for challengeId: String, completion: @escaping ([ParticipantProgress]) -> Void)
    func updateProgress(for challengeId: String, progress: ParticipantProgress, completion: ((Error?) -> Void)?)
    func setUserProgress(userId: String, challengeId: String, progress: ParticipantProgress) throws
    func fetchProgress(challengeId: String, userId: String) async throws -> ParticipantProgress?

    // Notifications
    func updateNotifications(for challenge: Challenge, config: [ChallengeNotification], completion: ((Error?) -> Void)?)

    // Chat
    func fetchChatMessages(for challengeId: String) async throws -> [ChallengeChatMessage]
    func addChatMessage(_ message: ChallengeChatMessage, to challengeId: String) async throws
}

final class ChallengeService: ChallengeServiceProtocol {
    static let shared = ChallengeService()

    private let firestoreDB = Firestore.firestore()
    private let firebaseStorage = Storage.storage()
    private let collecChallenges = "challenges"
    private let collecPhotos = "photos"
    private let collecParticipants = "participants"
    private let collecComments = "comments"
    private let collecChat = "chatMessages"

    private init() {}
}

// MARK: - Challenges
extension ChallengeService {
    /// Récupère tous les défis présents dans Firestore sans filtrage
    func fetchAllChallenges() async throws -> [Challenge] {
        do {
            let snapshot = try await firestoreDB.collection(collecChallenges).getDocuments()
            let challenges = try snapshot.documents.map { try $0.data(as: Challenge.self) }

            return challenges
        } catch {
            print("❌ Erreur Firestore dans fetchAllChallengesOnceAsync: \(error)")
            return []
        }
    }

    func addChallenge(_ challenge: Challenge) async throws -> Challenge? {
        do {
            let docRef = try firestoreDB.collection(collecChallenges).addDocument(from: challenge)
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

        let ref = firestoreDB.collection(collecChallenges).document(challengeId)

        do {
            try ref.setData(from: challenge) { error in
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

    func deleteChallenge(challengeId: String) async throws {
        let challengePhotos = try await fetchPhotos(for: challengeId)

        // 1. Supprimer les photos dans Storage + Firestore
        for photo in challengePhotos {
            try await deletePhoto(photo)
        }

        // 2. Supprimer les documents collecParticipants dans Firestore
        try await deleteParticipantDocument(challengeId: challengeId)

        // 3. Supprimer le document du challenge
        try await deleteChallengeDocument(challengeId: challengeId)
    }

    // Privates

    private func deleteChallengeDocument(challengeId: String) async throws {
        let ref = firestoreDB.collection(collecChallenges).document(challengeId)

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

    private func deleteParticipantDocument(challengeId: String) async throws {
        let snapshot = try await firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecParticipants)
            .getDocuments()

        for doc in snapshot.documents {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                doc.reference.delete { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
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
        let ref = firebaseStorage.reference().child("photos/\(challengeId)/\(author.id ?? "unknown")/\(fileName)")

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
        let allPhotos = try await firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .getDocuments()

        return allPhotos.documents.compactMap { try? $0.data(as: ChallengePhoto.self) }
    }

    func deletePhoto(_ photo: ChallengePhoto) async throws {
        try await deletePhotosInStorage(photo: photo)
        try await deletePhotoInFirestore(photo: photo)
    }

    // Privates

    private func deletePhotosInStorage(photo: ChallengePhoto) async throws {
        let ref = firebaseStorage.reference(forURL: photo.imageUrl)

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

    private func deletePhotoInFirestore(photo: ChallengePhoto) async throws {
        guard let photoId = photo.id, let challengeId = photo.challengeId else { return }

        let photoRef = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(photoId)

        // 1. Supprimer les commentaires de la photo
        let snapshot = try await photoRef.collection(collecComments).getDocuments()

        for doc in snapshot.documents {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                doc.reference.delete { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }

        // 2. Supprimer la photo principale
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            photoRef.delete { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func savePhoto(_ photo: ChallengePhoto, challengeId: String) throws {
        let docRef = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document()

        var photoToSave = photo
        photoToSave.id = docRef.documentID
        try docRef.setData(from: photoToSave)
    }
}

// MARK: - Chat
extension ChallengeService {
    func fetchChatMessages(for challengeId: String) async throws -> [ChallengeChatMessage] {
        let snapshot = try await firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecChat)
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: ChallengeChatMessage.self) }
    }

    func addChatMessage(_ message: ChallengeChatMessage, to challengeId: String) async throws {
        try firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecChat)
            .addDocument(from: message)
    }
}

// MARK: - Reward flow
extension ChallengeService {
    func addParticipant(to challengeId: String, progress: ParticipantProgress, completion: ((Error?) -> Void)? = nil) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecParticipants)
            .document(progress.id)

        do {
            try ref.setData(from: progress) { error in
                completion?(error)
            }
        } catch {
            completion?(error)
        }
    }

    func fetchParticipants(for challengeId: String, completion: @escaping ([ParticipantProgress]) -> Void) {
        let ref = firestoreDB.collection(collecChallenges).document(challengeId).collection(collecParticipants)

        ref.addSnapshotListener { snapshot, error in
            let progresses = snapshot?.documents.compactMap { try? $0.data(as: ParticipantProgress.self) } ?? []

            completion(progresses)
        }
    }

    func fetchParticipantsProgress(for challengeId: String) async throws -> [ParticipantProgress] {
        let snapshot = try await firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecParticipants)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: ParticipantProgress.self) }
    }

    func updateProgress(for challengeId: String, progress: ParticipantProgress, completion: ((Error?) -> Void)? = nil) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecParticipants)
            .document(progress.id)

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
    //        let ref = firestoreDB.collection(collection).document(challengeId).collection(collecParticipants).document(userId)
    //        ref.updateData([
    //            "medals": FieldValue.arrayUnion([try! Firestore.Encoder().encode(medal)])
    //        ]) { error in
    //            completion?(error)
    //        }
    //    }

    func setUserProgress(userId: String, challengeId: String, progress: ParticipantProgress) throws {
        return try firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecParticipants)
            .document(userId)
            .setData(from: progress)
    }

    func fetchProgress(challengeId: String, userId: String) async throws -> ParticipantProgress? {
        let snapshot = try await firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecParticipants)
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
            return ["dayIndex": notif.dayIndex,
                    "times": notif.times.map { Timestamp(date: $0) }] as [String : Any]
        }

        guard let challengeId = challenge.id else { return }

        let ref = firestoreDB.collection(collecChallenges).document(challengeId)

        ref.updateData([
            "notificationsConfig": firestoreConfig
        ]) { error in
            completion?(error)
        }
    }
}

// MARK: - Like/Unlike Photo
extension ChallengeService {
    func likePhoto(challengeId: String, photoId: String, userId: String, completion: ((Error?) -> Void)? = nil) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(photoId)

        ref.updateData(["likes": FieldValue.arrayUnion([userId])]) { error in
            completion?(error)
        }
    }

    func unlikePhoto(challengeId: String, photoId: String, userId: String, completion: ((Error?) -> Void)? = nil) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(photoId)

        ref.updateData(["likes": FieldValue.arrayRemove([userId])]) { error in
            completion?(error)
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

        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(photoId)
            .collection(collecComments)

        ref.addDocument(data: commentData) { error in
            completion?(error)
        }
    }

    func listenToComments(challengeId: String, photoId: String, onUpdate: @escaping ([PhotoCommentModel]) -> Void) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(photoId)
            .collection(collecComments)


        ref.order(by: "timestamp").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return onUpdate([]) }

            let comments = documents.compactMap { try? $0.data(as: PhotoCommentModel.self) }

            onUpdate(comments)
        }
    }

    func listenToPhoto(challengeId: String, photoId: String, onUpdate: @escaping (ChallengePhoto?) -> Void) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(photoId)

        ref.addSnapshotListener { snapshot, error in
            guard let updatedPhoto = try? snapshot?.data(as: ChallengePhoto.self) else { return onUpdate(nil) }

            onUpdate(updatedPhoto)
        }
    }
}

// TODO: Pas ici
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
