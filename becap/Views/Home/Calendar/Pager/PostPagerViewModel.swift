//
//  PostPagerViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//

import Foundation
import FirebaseFirestore

final class PostStore: ObservableObject {
    static let shared = PostStore()

    private struct CacheEntry {
        let viewModel: PostViewModel
        var lastAccess: Date
    }

    private let maxCacheSize = 40
    private var cache: [String: CacheEntry] = [:]
    private let lock = NSLock()

    func getViewModel(for post: ChallengePost) -> PostViewModel {
        let key = makeKey(for: post)

        lock.lock()
        defer { lock.unlock() }

        if var entry = cache[key] {
            entry.lastAccess = Date()
            cache[key] = entry
            return entry.viewModel
        }

        let vm = PostViewModel(post: post)
        cache[key] = CacheEntry(viewModel: vm, lastAccess: Date())
        trimIfNeeded()

        return vm
    }

    func removeViewModel(for photo: ChallengePost) {
        let key = makeKey(for: photo)

        lock.lock()
        defer { lock.unlock() }

        if let entry = cache.removeValue(forKey: key) {
            entry.viewModel.invalidate()
        }
    }

    private func makeKey(for photo: ChallengePost) -> String {
//        if let photoId = photo.id, !photoId.isEmpty {
//            return photoId
//        }

        let challengeComponent = photo.challengeId
        let timestamp = photo.date.timeIntervalSince1970

        return "\(challengeComponent)_\(photo.authorUid)_\(timestamp)"
    }

    private func trimIfNeeded() {
        guard cache.count > maxCacheSize else { return }

        let overflow = cache.count - maxCacheSize
        let keysToRemove = cache
            .sorted { $0.value.lastAccess < $1.value.lastAccess }
            .prefix(overflow)
            .map { $0.key }

        for key in keysToRemove {
            if let entry = cache.removeValue(forKey: key) {
                entry.viewModel.invalidate()
            }
        }
    }
}

final class PostViewModel: ObservableObject, Identifiable {
    @Published var likes: [String]
    @Published var comments: [PostCommentModel] = []
	@Published var jokerState: PhotoJokerState

    let post: ChallengePost

    private let challengeService: ChallengeServiceProtocol
    private let challengeManager: ChallengeManagerProtocol
    private var likesListener: ListenerRegistration?
    private var commentsListener: ListenerRegistration?

    var postFormattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE d MMMM 'à' HH:mm"
        dateFormatter.locale = Locale(identifier: "fr_FR")

        return dateFormatter.string(from: post.date)
    }

    init(post: ChallengePost,
         challengeService: ChallengeServiceProtocol = ChallengeService.shared,
         challengeManager: ChallengeManagerProtocol = ChallengeManager.shared) {
        self.post = post
        self.likes = post.likes ?? []
		self.jokerState = post.jokerState ?? PhotoJokerState()
        self.challengeService = challengeService
        self.challengeManager = challengeManager

        listenToPost()
    }

    deinit {
        invalidate()
    }

    func like() {
        guard let currentUserId = challengeManager.currentUser?.id, !likes.contains(currentUserId) else { return }

        likes.append(currentUserId)

        Task {
            try await challengeManager.likePost(post: post)
        }
    }

    func unlike() {
        guard let currentUserId = challengeManager.currentUser?.id, likes.contains(currentUserId) else { return }

        likes.removeAll { $0 == currentUserId }

        Task {
            try await challengeManager.unlikePost(post: post)
        }
    }

    func addComment(post: ChallengePost, content: String) {
        let trimmedComment = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedComment.isEmpty else { return }

        Task {
            try await challengeManager.commentPost(post: post, content: trimmedComment)
        }
    }

    func toggleJokerVote() {
        Task {
            try await challengeManager.toggleJokerVote(for: post)
        }
    }

    func declareJokerUsage(in challenge: Challenge) {
        Task {
            try await challengeManager.declareJokerUsage(for: challenge,
                                                         on: post.date,
                                                         photoId: post.id)
        }
    }

    private func listenToPost() {
        listenToLikes(postId: post.id, challengeId: post.challengeId)
        listenToComments(postId: post.id, challengeId: post.challengeId)
    }

    private func listenToLikes(postId: String, challengeId: String) {
        challengeService.listenToPost(challengeId: challengeId, postId: postId) { [weak self] updated in
            guard let updated else { return }

            self?.likes = updated.likes ?? []
            self?.jokerState = updated.jokerState ?? PhotoJokerState()
        }
    }

    private func listenToComments(postId: String, challengeId: String) {
        challengeService.listenToComments(challengeId: challengeId, postId: postId) { [weak self] updated in
            self?.comments = updated
        }
    }

    func invalidate() {
        likesListener?.remove()
        likesListener = nil
        commentsListener?.remove()
        commentsListener = nil
    }
}

class PostPagerViewModel: ObservableObject {
    @Published var postViewModels: [PostViewModel]
    @Published var selectedPostVM: PostViewModel
    @Published var selectedIndex: Int {
        didSet {
            selectedPostVM = postViewModels[selectedIndex]
        }
    }

    private let challengeService: ChallengeServiceProtocol
    private let challengeManager: ChallengeManagerProtocol
    let challenge: Challenge

    var postFormattedDate: String {
        selectedPostVM.postFormattedDate
    }

    var canDeletePost: Bool {
        guard let currentUserId = challengeManager.currentUser?.id else { return false }

        return selectedPostVM.post.authorUid == currentUserId
    }

    var canToggleJokerVote: Bool {
        guard let currentUserId = challengeManager.currentUser?.id else { return false }

        return currentUserId != selectedPostVM.post.authorUid
    }

    var canDeclareJoker: Bool {
        guard let currentUserId = challengeManager.currentUser?.id else { return false }

        return currentUserId == selectedPostVM.post.authorUid
    }

    var selectedJokerState: PhotoJokerState {
        selectedPostVM.jokerState
    }

    init(challengeService: ChallengeServiceProtocol = ChallengeService.shared,
         challengeManager: ChallengeManagerProtocol = ChallengeManager.shared,
         posts: [ChallengePost],
         selectedPostIndex: Int = 0,
         challenge: Challenge) {
        self.challengeService = challengeService
        self.challengeManager = challengeManager
        self.challenge = challenge

        // Créé un cache de l'ensemble des VM pour chaque photo et évite de les récréer à chaque ouverture de la pagerView
        let postViewModels = posts.map { PostStore.shared.getViewModel(for: $0) }
        self.selectedIndex = selectedPostIndex
        self.selectedPostVM = postViewModels[selectedPostIndex]
        self.postViewModels = postViewModels
    }

    func deletePost(isDeleted: @escaping (Bool, ChallengePost?) -> Void) {
        let deletedPost = selectedPostVM.post

        Task {
            do {
                try await challengeManager.deletePost(deletedPost)

                await MainActor.run {
                    self.postViewModels.removeAll(where: { $0.post.id == deletedPost.id })
					PostStore.shared.removeViewModel(for: deletedPost)

                    if !self.postViewModels.isEmpty {
                        if selectedIndex > 0 {
                            self.selectedIndex = selectedIndex - 1
                        } else {
                            self.selectedIndex = 0
                        }
                    }

                    isDeleted(true, deletedPost)
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
        selectedPostVM.like()
        // Force reload de la vue -> obligatoire car selectedPostVM.like() n'est pas observé par la vue
        reloadView()
    }

    func unlikeAction() {
        selectedPostVM.unlike()
        // Force reload de la vue -> obligatoire car selectedPostVM.unlike() n'est pas observé par la vue
        reloadView()
    }

    func toggleJokerVote() {
        guard canToggleJokerVote,
              let currentUserId = challengeManager.currentUser?.id else { return }

        var state = selectedPostVM.jokerState

        if state.voters.contains(currentUserId) {
            state.voters.removeAll { $0 == currentUserId }
        } else {
            state.voters.append(currentUserId)
        }

        let participantCount = max(1, challenge.participantUids.count)
        let requiredVotes = participantCount <= 2 ? participantCount : (participantCount / 2 + 1)
        let isConfirmed = state.voters.count >= requiredVotes

        state.isConfirmed = isConfirmed
        state.confirmedAt = isConfirmed ? Date() : nil

        selectedPostVM.jokerState = state
        objectWillChange.send()

        selectedPostVM.toggleJokerVote()
    }

    func declareJokerUsage() {
        guard canDeclareJoker,
              let currentUserId = challengeManager.currentUser?.id else { return }

        var state = selectedPostVM.jokerState
        state.declaredByAuthor = true

        if !state.voters.contains(currentUserId) {
            state.voters.append(currentUserId)
        }

        state.isConfirmed = true
        state.confirmedAt = Date()

        selectedPostVM.jokerState = state
        objectWillChange.send()

        selectedPostVM.declareJokerUsage(in: challenge)
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
