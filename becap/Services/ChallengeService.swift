//
//  ChallengeService.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import AVFoundation

enum ChallengeServiceError: Error {
    case invalidImageData(String)
}

protocol ChallengeServiceProtocol {
    // Challenges
    func fetchAllChallenges() async throws -> [Challenge]
    func addChallenge(_ challenge: Challenge) async throws -> Challenge?
    func updateChallenge(_ challenge: Challenge) async throws
    func deleteChallenge(challengeId: String) async throws

    // Posts
    func fetchPosts(for challengeId: String) async throws -> [ChallengePost]
    func uploadPost(rawMedia: ChallengeRawMedia, challengeId: String, author: User, description: String?) async throws -> ChallengePost
    func deletePost(_ post: ChallengePost) async throws
    func listenToPost(challengeId: String, postId: String, onUpdate: @escaping (ChallengePost?) -> Void) -> ListenerRegistration?
    func listenToComments(challengeId: String, postId: String, onUpdate: @escaping ([PostCommentModel]) -> Void) -> ListenerRegistration?

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
    func addReaction(_ reaction: String, to messageId: String, in challengeId: String, userId: String) async throws
    func removeReaction(_ reaction: String, from messageId: String, in challengeId: String, userId: String) async throws
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

            return challenges.filter { $0.id != "" }
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
        let ref = firestoreDB.collection(collecChallenges).document(challenge.id)

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
        let challengePosts = try await fetchPosts(for: challengeId)

        // 1. Supprimer les photos dans Storage + Firestore
        for post in challengePosts {
            try await deletePost(post)
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

// MARK: - Posts
extension ChallengeService {
    func uploadPost(rawMedia: ChallengeRawMedia, challengeId: String, author: User, description: String?) async throws -> ChallengePost {
        guard let authorId = author.id else { throw ChallengeServiceError.invalidImageData("Invalid image data") }

        var challengeMedia: ChallengeMedia?

        switch rawMedia {
        case .image(let uiImage):
            let firestoreImageUrl = try await saveImageToStorage(image: uiImage, challengeId: challengeId, authorId: authorId)
            challengeMedia = .image(url: firestoreImageUrl.absoluteString)
        case .video(let data):
            let firestoreVideoUrls = try await saveVideoToStorage(data: data, challengeId: challengeId, authorId: authorId)
            let videoData = ChallengeMedia.VideoData(videoURL: firestoreVideoUrls.videoUrl.absoluteString,
                                                     thumbnailURL: firestoreVideoUrls.thmbnailUrl?.absoluteString)
            challengeMedia = .video(videoData)
        }

        guard let challengeMedia else { throw ChallengeServiceError.invalidImageData("Invalid image data") }

        let post = ChallengePost(challengeId: challengeId,
                                 authorUid: authorId,
                                 authorName: author.name,
                                 description: description,
                                 date: Date(),
                                 //                                 createdAt: Date(),
                                 media: challengeMedia)

        try savePostToFirebase(post, challengeId: challengeId)

        return post
    }

    func fetchPosts(for challengeId: String) async throws -> [ChallengePost] {
        let allPosts = try await firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .getDocuments()

        return allPosts.documents.compactMap { try? $0.data(as: ChallengePost.self) }
    }

    func deletePost(_ post: ChallengePost) async throws {
        try await deletePostInStorage(post: post)
        try await deletePostInFirestore(post: post)
    }

    // Privates

    private func saveVideoToStorage(data: ChallengeRawMedia.VideoRawData,
                                    challengeId: String,
                                    authorId: String) async throws -> (videoUrl: URL, thmbnailUrl: URL?) {
        let mediaUuid = UUID().uuidString
        let folder = "\(mediaUuid)"

        /// Video
        let videoFileName = "\(mediaUuid).mp4"
        let videoRef = firebaseStorage.reference().child("videos/\(challengeId)/\(authorId)/\(folder)/\(videoFileName)")
        let compressedVideoURL = try await compressVideo(inputURL: data.url)

        _ = try await videoRef.putFileAsync(from: compressedVideoURL, metadata: nil)

        let downloadedVideoUrl = try await videoRef.downloadURL()

        /// Thumbnail
        var downloadedThumbnailUrl: URL?
        if let thumbnailImage = data.thumbnailImage {
            let resizedImage = thumbnailImage.resized(toMaxWidth: 720)

            guard let data = resizedImage.jpegData(compressionQuality: 0.6) else {
                throw ChallengeServiceError.invalidImageData("Invalid image data")
            }

            let thumbnailFileName = "\(mediaUuid).jpg"
            let thumbnailRef = firebaseStorage.reference().child("videos/\(challengeId)/\(authorId)/\(folder)/\(thumbnailFileName)")

            _ = try await thumbnailRef.putDataAsync(data, metadata: nil)

            downloadedThumbnailUrl = try await thumbnailRef.downloadURL()
        }

        return (downloadedVideoUrl, downloadedThumbnailUrl)
    }

    private func compressVideo(inputURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: inputURL)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "CompressionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de créer une session d'exportation"])
        }

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")

        try await exportSession.export(to: outputURL, as: .mp4)

        return outputURL
    }

    private func saveImageToStorage(image: UIImage, challengeId: String, authorId: String) async throws -> URL {
        let resizedImage = image.resized(toMaxWidth: 720)

        guard let data = resizedImage.jpegData(compressionQuality: 0.6) else {
            throw ChallengeServiceError.invalidImageData("Invalid image data")
        }

        let fileName = "\(UUID().uuidString).jpg"
        let ref = firebaseStorage.reference().child("photos/\(challengeId)/\(authorId)/\(fileName)")

        // Upload image to Storage
        _ = try await ref.putDataAsync(data, metadata: nil)

        // Get download URL
        return try await ref.downloadURL()
    }

    private func deletePostInStorage(post: ChallengePost) async throws {
        switch post.media {
        case .image(let urlString):
            try await deleteStorageFile(at: urlString)

        case .video(let videoData):
            try await deleteStorageFile(at: videoData.videoURL)

            if let thumbURL = videoData.thumbnailURL {
                try await deleteStorageFile(at: thumbURL)
            }
        }
    }

    private func deleteStorageFile(at urlString: String) async throws {
        let ref = firebaseStorage.reference(forURL: urlString)

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

    // TODO: Différencier photo et vidéo pour adapter ref
    private func deletePostInFirestore(post: ChallengePost) async throws {
        let postRef = firestoreDB
            .collection(collecChallenges)
            .document(post.challengeId)
            .collection(collecPhotos)
            .document(post.id)

        // 1. Supprimer les commentaires de la photo
        let snapshot = try await postRef.collection(collecComments).getDocuments()

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
            postRef.delete { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func savePostToFirebase(_ post: ChallengePost, challengeId: String) throws {
        let docRef = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document()

		try docRef.setData(from: post)
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

    func addReaction(_ reaction: String,
                     to messageId: String,
                     in challengeId: String,
                     userId: String) async throws {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecChat)
            .document(messageId)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.updateData([
                "reactions.\(reaction)": FieldValue.arrayUnion([userId])
            ]) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func removeReaction(_ reaction: String,
                        from messageId: String,
                        in challengeId: String,
                        userId: String) async throws {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecChat)
            .document(messageId)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.updateData([
                "reactions.\(reaction)": FieldValue.arrayRemove([userId])
            ]) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
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

        let ref = firestoreDB.collection(collecChallenges).document(challenge.id)

        ref.updateData([
            "notificationsConfig": firestoreConfig
        ]) { error in
            completion?(error)
        }
    }
}

// MARK: - Like/Unlike Post
extension ChallengeService {
    func likePost(challengeId: String, postId: String, userId: String, completion: ((Error?) -> Void)? = nil) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(postId)

        ref.updateData(["likes": FieldValue.arrayUnion([userId])]) { error in
            completion?(error)
        }
    }

    func unlikePost(challengeId: String, postId: String, userId: String, completion: ((Error?) -> Void)? = nil) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(postId)

        ref.updateData(["likes": FieldValue.arrayRemove([userId])]) { error in
            completion?(error)
        }
    }
}

// MARK: - Comments
extension ChallengeService {
    func addComment(postId: String,
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
            .document(postId)
            .collection(collecComments)

        ref.addDocument(data: commentData) { error in
            completion?(error)
        }
    }

    func listenToComments(challengeId: String, postId: String, onUpdate: @escaping ([PostCommentModel]) -> Void) -> ListenerRegistration? {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(postId)
            .collection(collecComments)


        let listener = ref.order(by: "timestamp").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return onUpdate([]) }

            let comments = documents.compactMap { try? $0.data(as: PostCommentModel.self) }

            onUpdate(comments)
        }

        return listener
    }

    func listenToPost(challengeId: String, postId: String, onUpdate: @escaping (ChallengePost?) -> Void) -> ListenerRegistration? {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(postId)

        let listener = ref.addSnapshotListener { snapshot, error in
            guard let updatedPost = try? snapshot?.data(as: ChallengePost.self) else { return onUpdate(nil) }

            onUpdate(updatedPost)
        }

        return listener
    }

    func updatePhotoJokerState(challengeId: String, photoId: String, state: PhotoJokerState) async throws {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(photoId)

        try await ref.updateData([
            "jokerState": try Firestore.Encoder().encode(state)
        ])
    }
}

import FirebaseAuth

extension ChallengeService {
    /// Upload un nouvel avatar et met à jour le profil utilisateur (champ `photoURL`)
    /// - Paramètre previousURL: l’ancienne URL (pour supprimer l’ancien fichier si tu veux)
    func updateUserAvatar(data: Data, previousURL: String? = nil) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // 1) Chemin unique pour éviter le cache client
        let filename = UUID().uuidString + ".jpg"
        let ref = firebaseStorage.reference()
            .child("avatars/\(uid)/\(filename)")

        // 2) Upload
        _ = try await ref.putDataAsync(data, metadata: nil)

        // 3) URL publique
        let url = try await ref.downloadURL()

        // 4) Sauvegarde Firestore
        try await firestoreDB.collection("users")
            .document(uid)
            .updateData(["photoURL": url.absoluteString])

        // 5) (Optionnel) Supprimer l’ancien fichier pour éviter d’encombrer le bucket
        if let prev = previousURL {
            let prevRef = firebaseStorage.reference(forURL: prev)

            try? await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
                prevRef.delete { _ in c.resume() } // on ignore l’erreur si le fichier n’existe plus
            }
        }
    }
}
