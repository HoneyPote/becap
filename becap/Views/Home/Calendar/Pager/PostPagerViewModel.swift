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

        // ⚠️ Tant que Firestore n’a pas renvoyé de documentId,
        // on NE met PAS en cache (sinon score / joker / likes cassés)
        guard !post.id.isEmpty else {
            return PostViewModel(post: post)
        }

        let key = post.id

        lock.lock()
        defer { lock.unlock() }

        // ✅ Cache hit
        if var entry = cache[key] {
            entry.lastAccess = Date()
            cache[key] = entry
            return entry.viewModel
        }

        // ❌ Cache miss → création
        let vm = PostViewModel(post: post)
        cache[key] = CacheEntry(
            viewModel: vm,
            lastAccess: Date()
        )

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
        if !post.id.isEmpty {
            return post.id // ✅ clé stable = documentId Firestore
        }

        // fallback si pas encore d'id (upload local)
        let timestamp = post.date.timeIntervalSince1970
        return "\(post.challengeId)_\(post.authorUid)_\(timestamp)"
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

    func toggleJokerVote(using currentState: PostJokerState? = nil) {
        Task {
            let state = currentState ?? jokerState
            try await challengeManager.toggleJokerVote(for: post, currentState: state)
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
    private var scoresUpdateCancellable: AnyCancellable?
    @Published var scoreCards: [String: ScoreCard] = [:]
    @Published var postViewModels: [PostViewModel]
    @Published var selectedPostVM: PostViewModel
    @Published var selectedJokerState: PostJokerState
    @Published var selectedIndex: Int {
        didSet {
            selectedPostVM = postViewModels[selectedIndex]
            selectedJokerState = selectedPostVM.jokerState
            bindToSelectedPostViewModel()
        }
    }

    private let challengeService: ChallengeServiceProtocol
    private let challengeManager: ChallengeManagerProtocol
    let challenge: Challenge

    private var selectedPostSubscription: AnyCancellable?
    private var selectedJokerSubscription: AnyCancellable?

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
        && !selectedJokerState.voters.contains(currentUserId)
    }

    var hasCurrentUserVoted: Bool {
        guard let currentUserId = challengeManager.currentUser?.id else { return false }

        return selectedJokerState.voters.contains(currentUserId)
    }

    var canDeclareJoker: Bool {
        guard let currentUserId = challengeManager.currentUser?.id else { return false }

        return currentUserId == selectedPostVM.post.authorUid
    }

    init(challengeService: ChallengeServiceProtocol = ChallengeService.shared,
         challengeManager: ChallengeManagerProtocol = ChallengeManager.shared,
         posts: [ChallengePost],
         selectedPostIndex: Int = 0,
         challenge: Challenge,
         initialScoreCards: [String: ScoreCard] = [:]) {
        self.challengeService = challengeService
        self.challengeManager = challengeManager
        self.challenge = challenge
        self.scoreCards = initialScoreCards

        // Créé un cache de l'ensemble des VM pour chaque photo et évite de les récréer à chaque ouverture de la pagerView
        let postViewModels = posts.map { PostStore.shared.getViewModel(for: $0) }
        self.selectedIndex = selectedPostIndex
        self.selectedPostVM = postViewModels[selectedPostIndex]
        self.selectedJokerState = postViewModels[selectedPostIndex].jokerState
        self.postViewModels = postViewModels
        
        scoresUpdateCancellable = NotificationCenter.default.publisher(for: .scoresDidUpdate)
            .compactMap { $0.object as? String }
            .filter { [weak self] updatedChallengeId in
                updatedChallengeId == self?.challenge.id
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshScores()
            }
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
    func refreshScores() {
        loadScores()
    }

    private func loadScores() {
        Task {
            let ids = postViewModels.map { $0.post.id }.filter { !$0.isEmpty }
            print("🧪 loadScores postIds=", ids)

            guard !ids.isEmpty else {
                await MainActor.run { self.scoreCards = [:] }
                return
            }

            do {
                let res = try await challengeManager.fetchPostScoreCards(for: challenge.id, postIds: ids)
                print("✅ loadScores res keys=", Array(res.keys))
                await MainActor.run { self.scoreCards = res }
            } catch {
                print("❌ loadScores error:", error)
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

        let baseState = selectedPostVM.jokerState
        var optimisticState = baseState

        if optimisticState.voters.contains(currentUserId) {
            return
        }

        optimisticState.voters.append(currentUserId)

        let eligibleVoters = max(challenge.participantUids.count - 1, 1)
        let requiredVotes = eligibleVoters <= 2 ? eligibleVoters : (eligibleVoters / 2 + 1)
        let isConfirmed = optimisticState.voters.count >= requiredVotes

        optimisticState.isConfirmed = isConfirmed
        optimisticState.confirmedAt = isConfirmed ? Date() : nil

        selectedPostVM.jokerState = optimisticState
        objectWillChange.send()

        selectedPostVM.toggleJokerVote(using: baseState)
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
        selectedPostSubscription?.cancel()
        selectedJokerSubscription?.cancel()

        selectedPostSubscription = selectedPostVM.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }

        selectedJokerSubscription = selectedPostVM.$jokerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.selectedJokerState = newState
            }
    }
}
