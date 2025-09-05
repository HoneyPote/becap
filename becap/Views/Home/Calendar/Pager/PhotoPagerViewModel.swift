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
        return "\(photo.authorUid)_\(photo.date.timeIntervalSince1970)"
    }
}

final class PhotoViewModel: ObservableObject, Identifiable {
    @Published var likes: [String]
    @Published var comments: [PhotoCommentModel] = []

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
        self.challengeService = challengeService
        self.challengeManager = challengeManager

        self.listenToPost()
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

    func listenToPost() {
        guard let photoId = photo.id, let challengeId = photo.challengeId else { return }

        listenToLikes(photoId: photoId, challengeId: challengeId)
        listenToComments(photoId: photoId, challengeId: challengeId)
    }

    private func listenToLikes(photoId: String, challengeId: String) {
        challengeService.listenToPhoto(challengeId: challengeId, photoId: photoId) { [weak self] updated in
            guard let updated else { return }

            self?.likes = updated.likes ?? []
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

    var photoFormattedDate: String {
        selectedPhotoVM.photoFormattedDate
    }

    var canDeletePhoto: Bool {
        guard let currentUserId = challengeManager.currentUser?.id else { return false }

        return selectedPhotoVM.photo.authorUid == currentUserId
    }

    init(challengeService: ChallengeServiceProtocol = ChallengeService.shared,
         challengeManager: ChallengeManagerProtocol = ChallengeManager.shared,
         photos: [ChallengePhoto],
         selectedPhotoIndex: Int = 0) {
        self.challengeService = challengeService
        self.challengeManager = challengeManager

        // Créé un cache de l'ensemble des VM pour chaque photo et évite de les récréer à chaque ouverture de la pagerView
        let photoViewModels = photos.map { PhotoStore.shared.getViewModel(for: $0) }
        self.selectedIndex = selectedPhotoIndex
        self.selectedPhotoVM = photoViewModels[selectedPhotoIndex]
        self.photoViewModels = photoViewModels
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
