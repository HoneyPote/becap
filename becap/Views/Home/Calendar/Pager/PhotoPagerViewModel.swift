//
//  PhotoPagerViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//

import Foundation

final class PhotoStore: ObservableObject {
    static let shared = PhotoStore()

    private var cache: [String: PhotoViewModel] = [:]

    func getViewModel(for photo: ChallengePhoto) -> PhotoViewModel {
        let key = makeKey(for: photo)

        if let existing = cache[key] {
            return existing
        } else {
            let vm = PhotoViewModel(photo: photo)
            cache[key] = vm
            return vm
        }
    }

    private func makeKey(for photo: ChallengePhoto) -> String {
          if let photoId = photo.id, !photoId.isEmpty {
              return photoId
          }

          let challengeComponent = photo.challengeId ?? "unknown"
          let timestamp = photo.createdAt.timeIntervalSince1970

          return "\(challengeComponent)_\(photo.authorUid)_\(timestamp)"
      
  }
}

final class PhotoViewModel: ObservableObject, Identifiable {
    @Published var likes: [String]
    @Published var comments: [PhotoCommentModel] = []
    @Published var jokerState: PhotoJokerState

    let photo: ChallengePhoto

    private let challengeService: ChallengeServiceProtocol
    private let challengeManager: ChallengeManagerProtocol

    var photoFormattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE d MMMM 'à' HH:mm"
        dateFormatter.locale = Locale(identifier: "fr_FR")

        return dateFormatter.string(from: photo.date)
    }

    init(photo: ChallengePhoto,
         challengeService: ChallengeServiceProtocol = ChallengeService.shared,
         challengeManager: ChallengeManagerProtocol = ChallengeManager.shared) {
        self.photo = photo
        self.likes = photo.likes ?? []
        self.jokerState = photo.jokerState ?? PhotoJokerState()
        self.challengeService = challengeService
        self.challengeManager = challengeManager

        listenToPost()
    }

    func like() {
        guard let currentUserId = challengeManager.currentUser?.id, !likes.contains(currentUserId) else { return }

        likes.append(currentUserId)

        Task {
            try await challengeManager.likePhoto(photo: photo)
        }
    }

    func unlike() {
        guard let currentUserId = challengeManager.currentUser?.id, likes.contains(currentUserId) else { return }

        likes.removeAll { $0 == currentUserId }

        Task {
            try await challengeManager.unlikePhoto(photo: photo)
        }
    }

    func addComment(photo: ChallengePhoto, content: String) {
        let trimmedComment = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedComment.isEmpty else { return }

        Task {
            try await challengeManager.commentPhoto(photo: photo, content: trimmedComment)
        }
    }

    func toggleJokerVote() {
        Task {
            try await challengeManager.toggleJokerVote(for: photo)
        }
    }

    func declareJokerUsage(in challenge: Challenge) {
        Task {
            try await challengeManager.declareJokerUsage(for: challenge,
                                                        on: photo.date,
                                                        photoId: photo.id)
        }
    }

    private func listenToPost() {
        guard let photoId = photo.id, let challengeId = photo.challengeId else { return }

        listenToLikes(photoId: photoId, challengeId: challengeId)
        listenToComments(photoId: photoId, challengeId: challengeId)
    }

    private func listenToLikes(photoId: String, challengeId: String) {
        challengeService.listenToPhoto(challengeId: challengeId, photoId: photoId) { [weak self] updated in
            guard let updated else { return }

            self?.likes = updated.likes ?? []
            self?.jokerState = updated.jokerState ?? PhotoJokerState()
        }
    }

    private func listenToComments(photoId: String, challengeId: String) {
        challengeService.listenToComments(challengeId: challengeId, photoId: photoId) { [weak self] updated in
            self?.comments = updated
        }
    }
}

class PhotoPagerViewModel: ObservableObject {
    @Published var photoViewModels: [PhotoViewModel]
    @Published var selectedPhotoVM: PhotoViewModel
    @Published var selectedIndex: Int {
        didSet {
            selectedPhotoVM = photoViewModels[selectedIndex]
        }
    }

    private let challengeService: ChallengeServiceProtocol
    private let challengeManager: ChallengeManagerProtocol
    let challenge: Challenge

    var photoFormattedDate: String {
        selectedPhotoVM.photoFormattedDate
    }

    var canDeletePhoto: Bool {
        guard let currentUserId = challengeManager.currentUser?.id else { return false }

        return selectedPhotoVM.photo.authorUid == currentUserId
    }

    var canToggleJokerVote: Bool {
        guard let currentUserId = challengeManager.currentUser?.id else { return false }

        return currentUserId != selectedPhotoVM.photo.authorUid
    }

    var canDeclareJoker: Bool {
        guard let currentUserId = challengeManager.currentUser?.id else { return false }

        return currentUserId == selectedPhotoVM.photo.authorUid
    }

    var selectedJokerState: PhotoJokerState {
        selectedPhotoVM.jokerState
    }

    init(challengeService: ChallengeServiceProtocol = ChallengeService.shared,
         challengeManager: ChallengeManagerProtocol = ChallengeManager.shared,
         photos: [ChallengePhoto],
         selectedPhotoIndex: Int = 0,
         challenge: Challenge) {
        self.challengeService = challengeService
        self.challengeManager = challengeManager
        self.challenge = challenge

        // Créé un cache de l'ensemble des VM pour chaque photo et évite de les récréer à chaque ouverture de la pagerView
        let photoViewModels = photos.map { PhotoStore.shared.getViewModel(for: $0) }
        self.selectedIndex = selectedPhotoIndex
        self.selectedPhotoVM = photoViewModels[selectedPhotoIndex]
        self.photoViewModels = photoViewModels
    }

    func deletePhoto(isDeleted: @escaping (Bool, ChallengePhoto?) -> Void) {
        let deletedPhoto = selectedPhotoVM.photo

        Task {
            do {
                try await challengeManager.deletePhoto(deletedPhoto)

                await MainActor.run {
                    self.photoViewModels.removeAll(where: { $0.photo.id == deletedPhoto.id })

                    if !self.photoViewModels.isEmpty {
                        if selectedIndex > 0 {
                            self.selectedIndex = selectedIndex - 1
                        } else {
                            self.selectedIndex = 0
                        }
                    }

                    isDeleted(true, deletedPhoto)
                }
            } catch let error {
                await MainActor.run {
                    print("Impossible de supprimer la photo. Error : \(error)")
                    isDeleted(false, nil)
                }
            }
        }
    }

    func likeAction() {
        selectedPhotoVM.like()
        // Force reload de la vue -> obligatoire car selectedPhotoVM.like() n'est pas observé par la vue
        reloadView()
    }

    func unlikeAction() {
        selectedPhotoVM.unlike()
        // Force reload de la vue -> obligatoire car selectedPhotoVM.unlike() n'est pas observé par la vue
        reloadView()
    }

    func toggleJokerVote() {
        guard canToggleJokerVote else { return }

        selectedPhotoVM.toggleJokerVote()
    }

    func declareJokerUsage() {
        guard canDeclareJoker else { return }

        selectedPhotoVM.declareJokerUsage(in: challenge)
    }

    func buildCommentFormattedDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM 'à' HH:mm"
        dateFormatter.locale = Locale(identifier: "fr_FR")

        return dateFormatter.string(from: date)
    }

    private func reloadView() {
        objectWillChange.send()
    }
}
