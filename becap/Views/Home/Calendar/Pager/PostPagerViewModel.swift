//
//  PostPagerViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//

import Foundation
import Combine
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

    func removeViewModel(for post: ChallengePost) {
        let key = makeKey(for: post)

        lock.lock()
        do { lock.unlock() }

        cache.removeValue(forKey: key)
    }

    private func makeKey(for post: ChallengePost) -> String {
        let challengeComponent = post.challengeId
        let timestamp = post.date.timeIntervalSince1970

        return "\(challengeComponent)_\(post.authorUid)_\(timestamp)"
    }

    private func trimIfNeeded() {
        guard cache.count > maxCacheSize else { return }

        let overflow = cache.count - maxCacheSize
        let keysToRemove = cache
            .sorted { $0.value.lastAccess < $1.value.lastAccess }
            .prefix(overflow)
            .map { $0.key }

        keysToRemove.forEach { cache.removeValue(forKey: $0) }
    }
}

final class PostViewModel: ObservableObject, Identifiable {
    @Published var likes: [String]
    @Published var comments: [PostCommentModel] = []
	@Published var jokerState: PostJokerState

    let post: ChallengePost

    private let challengeService: ChallengeServiceProtocol
    private let challengeManager: ChallengeManagerProtocol

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
		self.jokerState = post.jokerState ?? PostJokerState()
        self.challengeService = challengeService
        self.challengeManager = challengeManager

        listenToPost()
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
            try await challengeManager.toggleJokerVote(for: post, currentState: jokerState)
        }
    }

    func declareJokerUsage(in challenge: Challenge) {
        Task {
            try await challengeManager.declareJokerUsage(for: challenge,
                                                         on: post.date,
                                                         postId: post.id)
        }
    }

    private func listenToPost() {
        listenToLikes(postId: post.id, challengeId: post.challengeId)
        listenToComments(postId: post.id, challengeId: post.challengeId)
    }

    private func listenToLikes(postId: String, challengeId: String) {
        challengeService.listenToPost(challengeId: challengeId, postId: postId) { [weak self] updated in
            guard let updated else { return }

            DispatchQueue.main.async {
                self?.likes = updated.likes ?? []
                self?.jokerState = updated.jokerState ?? PostJokerState()
            }
        }
    }

    private func listenToComments(postId: String, challengeId: String) {
        challengeService.listenToComments(challengeId: challengeId, postId: postId) { [weak self] updated in
            DispatchQueue.main.async {
                self?.comments = updated
            }
        }
    }
}

class PostPagerViewModel: ObservableObject {
    @Published var postViewModels: [PostViewModel]
    @Published var selectedPostVM: PostViewModel
    @Published var selectedIndex: Int {
        didSet {
            selectedPostVM = postViewModels[selectedIndex]
            bindToSelectedPostViewModel()
        }
    }

    private let challengeService: ChallengeServiceProtocol
    private let challengeManager: ChallengeManagerProtocol
    let challenge: Challenge

    private var selectedPostSubscription: AnyCancellable?

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
        && !selectedPostVM.jokerState.voters.contains(currentUserId)
    }

    var hasCurrentUserVoted: Bool {
        guard let currentUserId = challengeManager.currentUser?.id else { return false }

        return selectedPostVM.jokerState.voters.contains(currentUserId)
    }

    var canDeclareJoker: Bool {
        guard let currentUserId = challengeManager.currentUser?.id else { return false }

        return currentUserId == selectedPostVM.post.authorUid
    }

    var selectedJokerState: PostJokerState {
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

        bindToSelectedPostViewModel()
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
            return
        }

        state.voters.append(currentUserId)

        let eligibleVoters = max(challenge.participantUids.count - 1, 1)
        let requiredVotes = eligibleVoters <= 2 ? eligibleVoters : (eligibleVoters / 2 + 1)
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

    private func bindToSelectedPostViewModel() {
        selectedPostSubscription = selectedPostVM.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
}
