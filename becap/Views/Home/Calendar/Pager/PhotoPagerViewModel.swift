//
//  PhotoPagerViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//

import Foundation
import Combine
import Firebase

class PhotoPagerViewModel: ObservableObject {
    @Published var currentPhoto: ChallengePhoto
    @Published var comments: [PhotoCommentModel] = []
    @Published var selectedPhotoIndex: Int {
        didSet {
            listenCurrentPhoto()
        }
    }

    private let challengeService: ChallengeServiceProtocol
    private let challengeManager: ChallengeManagerProtocol

    let allPhotos: [ChallengePhoto]

    private var photoListener: ListenerRegistration?
    private var commentsListener: ListenerRegistration?

    var photoFormatedDate: String {
        let dayTimeFormatter = DateFormatter()
        dayTimeFormatter.dateFormat = "EEEE d MMMM 'à' HH:mm"
        dayTimeFormatter.locale = Locale(identifier: "fr_FR")

        return dayTimeFormatter.string(from: currentPhoto.date)
    }

    init(challengeService: ChallengeServiceProtocol = ChallengeService.shared,
         challengeManager: ChallengeManagerProtocol = ChallengeManager.shared,
         photos: [ChallengePhoto],
         selectedPhotoIndex: Int = 0) {
        self.challengeService = challengeService
        self.challengeManager = challengeManager
        self.allPhotos = photos
        self.selectedPhotoIndex = selectedPhotoIndex
        self.currentPhoto = allPhotos[selectedPhotoIndex]
    }

    func listenCurrentPhoto() {
        guard !allPhotos.isEmpty,
              selectedPhotoIndex < allPhotos.count,
              let challengeId = allPhotos[selectedPhotoIndex].challengeId,
              let photoId = allPhotos[selectedPhotoIndex].id else { return }

        listenToPhotoRealtime(challengeId: challengeId, photoId: photoId)
        listenToComments(challengeId: challengeId, photoId: photoId)
    }

    func canDeletePhoto() -> Bool {
        guard let currentUserId = challengeManager.currentUser?.id else { return false }

        return currentPhoto.authorUid == currentUserId
    }

    func listenToPhotoRealtime(challengeId: String, photoId: String) {
        photoListener?.remove()
        photoListener = challengeService.listenToPhoto(challengeId: challengeId, photoId: photoId) { [weak self] updatedPhoto in
            guard let updatedPhoto else { return }

            DispatchQueue.main.async {
                self?.currentPhoto = updatedPhoto
            }
        }
    }

    func listenToComments(challengeId: String, photoId: String) {
        commentsListener?.remove()
        commentsListener = challengeService.listenToComments(challengeId: challengeId, photoId: photoId) { [weak self] newComments in
            DispatchQueue.main.async {
                self?.comments = newComments
            }
        }
    }

    func addComment(content: String) {
        let trimmedComment = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedComment.isEmpty else { return }

        Task {
            try await challengeManager.commentPhoto(photo: currentPhoto, content: trimmedComment)
        }
    }

    func like() {
        Task {
            try await challengeManager.likePhoto(photo: currentPhoto)
        }
    }

    func unlike() {
        Task {
            try await challengeManager.unlikePhoto(photo: currentPhoto)
        }
    }

    deinit {
        stopListening()
    }

    private func stopListening() {
        photoListener?.remove()
        commentsListener?.remove()
    }
}
