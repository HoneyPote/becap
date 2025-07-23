//
//  ChallengeService.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

// ChallengeService.swift

import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

enum ChallengeServiceError: Error {
    case invalidImageData(String)
}

final class ChallengeService {
    static let shared = ChallengeService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let collection = "challenges"

    private init() {}

    // MARK: - Challenges

    func fetchChallenges(completion: @escaping ([Challenge]) -> Void) {
        db.collection(collection).addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else {
                completion([])
                return
            }
            let challenges = docs.compactMap { try? $0.data(as: Challenge.self) }
            completion(challenges)
        }
    }

    func addChallenge(_ challenge: Challenge, completion: ((Error?) -> Void)? = nil) {
        do {
            _ = try db.collection(collection).addDocument(from: challenge) { error in
                completion?(error)
            }
        } catch {
            completion?(error)
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

    // MARK: - Participants

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

    // MARK: - Médailles

    func addMedal(for challengeId: String, userId: String, medal: UserMedal, completion: ((Error?) -> Void)? = nil) {
        let ref = db.collection(collection).document(challengeId).collection("participants").document(userId)
        ref.updateData([
            "medals": FieldValue.arrayUnion([try! Firestore.Encoder().encode(medal)])
        ]) { error in
            completion?(error)
        }
    }

    // MARK: - Photos

    func uploadPhoto(image: UIImage, challengeId: String, author: User, description: String?) async throws {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ChallengeServiceError.invalidImageData("Invalid image data")
        }

        let fileName = "\(UUID().uuidString).jpg"
        let ref = storage.reference().child("photos/\(challengeId)/\(author.id ?? "unknown")/\(fileName)")

        // Upload image
        _ = try await ref.putDataAsync(data, metadata: nil)

        // Get download URL
        let url = try await ref.downloadURL()

        // Create photo
        let photo = ChallengePhoto(
            authorUid: author.id ?? "",
            authorName: author.name,
            imageUrl: url.absoluteString,
            description: description,
            date: Date(),
            createdAt: Date()
        )

        // Save in Firestore
        let docRef = db.collection(collection).document(challengeId).collection("photos").document()
        var photoToSave = photo
        photoToSave.id = docRef.documentID
        try docRef.setData(from: photoToSave)
    }

    private func savePhoto(_ photo: ChallengePhoto, challengeId: String, completion: @escaping (Result<ChallengePhoto, Error>) -> Void) {
        do {
            let ref = db.collection(collection).document(challengeId).collection("photos").document()
            var photoToSave = photo
            photoToSave.id = ref.documentID
            try ref.setData(from: photoToSave) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(photoToSave))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func fetchPhotos(for challengeId: String, completion: @escaping ([ChallengePhoto]) -> Void) {
        db.collection(collection).document(challengeId).collection("photos")
//            .order(by: "date")
            .addSnapshotListener { snapshot, error in
                let photos = snapshot?.documents.compactMap { try? $0.data(as: ChallengePhoto.self) } ?? []
                completion(photos)
            }
    }
}
