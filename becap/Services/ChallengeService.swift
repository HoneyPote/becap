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
    func fetchChallenge(by id: String) async throws -> Challenge?
    func fetchChallenge(byCode code: String) async throws -> Challenge?
    func addChallenge(_ challenge: Challenge) async throws -> Challenge?
    func updateChallenge(_ challenge: Challenge) async throws
    func deleteChallenge(challengeId: String) async throws
    func listenToGroupChat(challengeId: String, onUpdate: @escaping ([ChallengeChatMessage]) -> Void)

    // Posts
    func fetchPost(challengeId: String, postId: String) async throws -> ChallengePost?
    func fetchPosts(for challengeId: String) async throws -> [ChallengePost]
    func uploadPost(rawMedia: ChallengeRawMedia, challengeId: String, author: User, description: String?) async throws -> ChallengePost
    func deletePost(_ post: ChallengePost) async throws
    func listenToPost(challengeId: String, postId: String, onUpdate: @escaping (ChallengePost?) -> Void)
    func listenToComments(challengeId: String, postId: String, onUpdate: @escaping ([PostCommentModel]) -> Void)

    // Reward flow
    func addParticipant(progress: ParticipantProgress, completion: ((Error?) -> Void)?)
    func setUserProgress(progress: ParticipantProgress) throws
    func fetchParticipantsProgress(for challengeId: String) async throws -> [ParticipantProgress]?
    func fetchProgress(challengeId: String, userId: String) async throws -> ParticipantProgress?

    // Notifications
    func updateChallengeNotifications(for challengeId: String, config: [Int], completion: ((Error?) -> Void)?)
    func updateUserNotifications(for userId: String, challengeId: String, config: [Int], completion: ((Error?) -> Void)?)

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
    private var groupChatListeners: [String: ListenerRegistration] = [:]

    private init() {}
}

// MARK: - Challenges
extension ChallengeService {
    /// Récupère tous les défis présents dans Firestore sans filtrage
    func fetchAllChallenges() async throws -> [Challenge] {
        do {
            let snapshot = try await firestoreDB.collection(collecChallenges).getDocuments()
            let challenges = snapshot.documents.compactMap { doc in
                return try? doc.data(as: Challenge.self)
            }

            return challenges.filter { $0.id != "" }
        } catch {
            print("❌ Erreur Firestore dans fetchAllChallengesOnceAsync: \(error)")
            return []
        }
    }

    func fetchChallenge(by id: String) async throws -> Challenge? {
        do {
            let snapshot = try await firestoreDB
                .collection(collecChallenges)
                .document(id)
                .getDocument()

            return try snapshot.data(as: Challenge.self)
        } catch {
            print("❌ Erreur Firestore lors de fetchChallenge(by:): \(error)")
            return nil
        }
    }

    func fetchChallenge(byCode code: String) async throws -> Challenge? {
        do {
            let snapshot = try await firestoreDB
                .collection(collecChallenges)
                .whereField("code", isEqualTo: code)
                .limit(to: 1)
                .getDocuments()

            guard let document = snapshot.documents.first else { return nil }

            return try document.data(as: Challenge.self)
        } catch {
            print("❌ Erreur Firestore lors de fetchChallenge(byCode:): \(error)")
            return nil
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

    func fetchAdminUids(for challengeId: String) async throws -> [String]? {
        let ref = firestoreDB.collection(collecChallenges).document(challengeId)

        do {
            let snapshot = try await ref.getDocument()
            let data = snapshot.data()

            return data?["adminUids"] as? [String]
        } catch {
            print("❌ Erreur Firestore fetchAdminUids: \(error)")
            return nil
        }
    }

    func addAdminUid(challengeId: String, uid: String) async throws {
        guard let currentAdmins = try? await fetchAdminUids(for: challengeId),
              !currentAdmins.contains(where: { $0 == uid })
        else { return }

        let ref = firestoreDB.collection(collecChallenges).document(challengeId)

        try await ref.updateData([
            "adminUids": FieldValue.arrayUnion([uid])
        ])
    }

    func removeAdminUid(challengeId: String, uid: String) async throws {
        guard let currentAdmins = try? await fetchAdminUids(for: challengeId),
              currentAdmins.contains(where: { $0 == uid })
        else { return }

        let ref = firestoreDB.collection(collecChallenges).document(challengeId)

        try await ref.updateData([
            "adminUids": FieldValue.arrayRemove([uid])
        ])
    }

    func blockParticipant(challengeId: String, userId: String) async throws {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecParticipants)
            .document(userId)

        try await ref.updateData([
            "isBlocked": true
        ])
    }

    func unblockParticipant(challengeId: String, userId: String) async throws {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecParticipants)
            .document(userId)

        try await ref.updateData([
            "isBlocked": false
        ])
    }

    func addParticipant(challengeId: String, userId: String) async throws {
        let ref = firestoreDB.collection(collecChallenges).document(challengeId)

        try await ref.updateData([
            "participantUids": FieldValue.arrayUnion([userId])
        ])
    }

    func removeParticipant(challengeId: String, userId: String) async throws {
        let ref = firestoreDB.collection(collecChallenges).document(challengeId)

        try await ref.updateData([
            "participantUids": FieldValue.arrayRemove([userId])
        ])
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
                                 media: challengeMedia)

        try savePostToFirebase(post, challengeId: challengeId)

        return post
    }

    func fetchPost(challengeId: String, postId: String) async throws -> ChallengePost? {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(postId)

        let snapshot = try await ref.getDocument()
        return try snapshot.data(as: ChallengePost.self)
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

    private func savePostToFirebase(_ post: ChallengePost, challengeId: String) throws {
        let docRef = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document()

        try docRef.setData(from: post)
    }

    private func saveVideoToStorage(data: ChallengeRawMedia.VideoRawData,
                                    challengeId: String,
                                    authorId: String) async throws -> (videoUrl: URL, thmbnailUrl: URL?) {
        let mediaUuid = UUID().uuidString
        let folder = "\(mediaUuid)"

        /// Video
        let videoFileName = "\(mediaUuid).mov"
        let videoRef = firebaseStorage.reference().child("videos/\(challengeId)/\(authorId)/\(folder)/\(videoFileName)")
        let compressedVideoURL = try await compressVideo(inputURL: data.url)

        let compressedVideoURLData = try Data(contentsOf: compressedVideoURL)
        let videoMetadata = StorageMetadata()
        videoMetadata.contentType = "video/mov"

        _ = try await videoRef.putDataAsync(compressedVideoURLData, metadata: videoMetadata)

        let downloadedVideoUrl = try await videoRef.downloadURL()

        /// Thumbnail
        var downloadedThumbnailUrl: URL?
        if let thumbnailImage = data.thumbnailImage {
            let resizedImage = thumbnailImage.resized(toMaxWidth: 720)

            guard let data = resizedImage.jpegData(compressionQuality: 0.4) else {
                throw ChallengeServiceError.invalidImageData("Invalid image data")
            }

            let thumbnailFileName = "\(mediaUuid).jpg"
            let thumbnailRef = firebaseStorage.reference().child("videos/\(challengeId)/\(authorId)/\(folder)/\(thumbnailFileName)")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            _ = try await thumbnailRef.putDataAsync(data, metadata: metadata)

            downloadedThumbnailUrl = try await thumbnailRef.downloadURL()
        }

        return (downloadedVideoUrl, downloadedThumbnailUrl)
    }

    private func compressVideo(inputURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: inputURL)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHEVCHighestQuality) else {
            throw NSError(domain: "CompressionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de créer une session d'exportation"])
        }

        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.outputFileType = .mov

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")

        try await exportSession.export(to: outputURL, as: .mov)

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

        // 1. Supprimer les commentaires du post
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

        // 2. Supprimer le post principal
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

        return snapshot.documents.compactMap { document in
            guard var message = try? document.data(as: ChallengeChatMessage.self) else { return nil }
            message.documentId = document.documentID
            return message
        }
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
    func addParticipant(progress: ParticipantProgress, completion: ((Error?) -> Void)? = nil) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(progress.challengeId)
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

    func fetchParticipantsProgress(for challengeId: String) async throws -> [ParticipantProgress]? {
        let snapshot = try await firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecParticipants)
            .getDocuments()

        let progresses = snapshot.documents.compactMap { try? $0.data(as: ParticipantProgress.self) }

        return progresses.isEmpty ? nil : progresses
    }

    func setUserProgress(progress: ParticipantProgress) throws {
        return try firestoreDB
            .collection(collecChallenges)
            .document(progress.challengeId)
            .collection(collecParticipants)
            .document(progress.userId)
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
    func updateChallengeNotifications(for challengeId: String,
                                      config: [Int],
                                      completion: ((Error?) -> Void)? = nil) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)

        ref.updateData([
            "defaultNotificationsConfig": config
        ]) { error in
            completion?(error)
        }
    }

    func updateUserNotifications(for userId: String,
                                 challengeId: String,
                                 config: [Int],
                                 completion: ((Error?) -> Void)? = nil) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecParticipants)
            .document(userId)

        ref.updateData([
            "notificationsConfig": config
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

    func listenToGroupChat(challengeId: String, onUpdate: @escaping ([ChallengeChatMessage]) -> Void) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecChat)

        groupChatListeners[challengeId]?.remove()

        groupChatListeners[challengeId] = ref.order(by: "createdAt").addSnapshotListener { snapshot, error in
            if let error {
                print("❌ Failed to listen group chat: \(error)")
            }

            guard let documents = snapshot?.documents else { return onUpdate([]) }

            let comments = documents.compactMap { document -> ChallengeChatMessage? in
                guard var message = try? document.data(as: ChallengeChatMessage.self) else { return nil }
                message.documentId = document.documentID
                return message
            }

            onUpdate(comments)
        }
    }

    func listenToComments(challengeId: String, postId: String, onUpdate: @escaping ([PostCommentModel]) -> Void) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(postId)
            .collection(collecComments)


        _ = ref.order(by: "timestamp").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return onUpdate([]) }

            let comments = documents.compactMap { try? $0.data(as: PostCommentModel.self) }

            onUpdate(comments)
        }
    }

    func listenToPost(challengeId: String, postId: String, onUpdate: @escaping (ChallengePost?) -> Void) {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(postId)

        _ = ref.addSnapshotListener { snapshot, error in
            guard let updatedPost = try? snapshot?.data(as: ChallengePost.self) else { return onUpdate(nil) }

            onUpdate(updatedPost)
        }
    }

    func updatePostJokerState(challengeId: String, postId: String, state: PostJokerState) async throws {
        let ref = firestoreDB
            .collection(collecChallenges)
            .document(challengeId)
            .collection(collecPhotos)
            .document(postId)

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


    func updateUserProfile(name: String, description: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let sanitizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        try await firestoreDB.collection("users")
            .document(uid)
            .updateData([
                "name": sanitizedName,
                "profileDescription": sanitizedDescription
            ])
    }

    func addParticipatingChallenge(to userId: String, challengeId: String) async throws {
        let ref = firestoreDB.collection("users").document(userId)

        try await ref.updateData([
            "participatingChallenges": FieldValue.arrayUnion([challengeId])
        ])
    }

    func removeParticipatingChallenge(to userId: String, challengeId: String) async throws {
        let ref = firestoreDB.collection("users").document(userId)

        try await ref.updateData([
            "participatingChallenges": FieldValue.arrayRemove([challengeId])
        ])
    }
}
