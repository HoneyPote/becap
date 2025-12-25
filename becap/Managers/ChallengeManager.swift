//
//  ChallengeManager.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI
import Combine
import OneSignalFramework

protocol ChallengeManagerProtocol {
    var currentUser: User? { get }
    var challenges: [Challenge] { get }
    var posts: [String: [ChallengePost]] { get }

    // Challenge
    func createChallenge(_ challenge: Challenge) async throws -> Challenge?
    func fetchAllChallenges() async throws -> [Challenge]
    func fetchAndFilterChallenges() async throws
    func ensureMembership(in challengeId: String) async throws
    func deleteChallenge(_ challengeId: String) async throws
    func joinChallenge(_ challenge: Challenge, userId: String) async throws
    func joinChallenge(withCode code: String) async throws -> Challenge

    // Posts
    func sendPostAndNotify(media: ChallengeRawMedia, challenge: Challenge, descriptionText: String?) async throws
    func loadPosts(from challengeId: String) async throws -> [ChallengePost]
    func deletePost(_ post: ChallengePost) async throws
    func likePost(post: ChallengePost) async throws
    func unlikePost(post: ChallengePost) async throws
    func commentPost(post: ChallengePost, content: String) async throws

    // Scores & leaderboard
    func fetchPostScoreCards(for challengeId: String, postIds: [String]) async throws -> [String: ScoreCard]
    func fetchScoreLeaderboard(for challengeId: String,
                               granularity: ScoreAggregation.Granularity) async throws -> [ScoreAggregation]

    // Reward flow
    func createNewParticipantProgress(userId: String, challenge: Challenge) async throws
    func updateParticipantProgress(for challengeId: String, userId: String, date: Date) async throws
    func assignCreationMedalsToUser(_ userId: String) async
    func declareJokerUsage(for challenge: Challenge, on date: Date, postId: String?) async throws
    func toggleJokerVote(for post: ChallengePost, currentState: PostJokerState) async throws

    // Notifications
    func updateNotifications(for challenge: Challenge, config: [ChallengeNotification], completion: ((Error?) -> Void)?)

    // Chat
    func fetchChatMessages(for challengeId: String) async throws -> [ChallengeChatMessage]
    func sendChatMessage(_ content: String, challengeId: String) async throws
    func markChatAsRead(for challengeId: String)
    func hasUnreadMessages(for challengeId: String, latestMessageDate: Date?) -> Bool
    func addChatReaction(_ reaction: String, to message: ChallengeChatMessage, challengeId: String, userId: String) async throws
    func removeChatReaction(_ reaction: String, from message: ChallengeChatMessage, challengeId: String, userId: String) async throws
}

enum ChallengeManagerError: LocalizedError {
    case userNotLoggedIn
    case challengeNotFound

    var errorDescription: String? {
        switch self {
        case .userNotLoggedIn:
            return "Vous devez être connecté pour rejoindre ce défi."
        case .challengeNotFound:
            return "Le défi partagé est introuvable ou n’existe plus."
        }
    }
}

class ChallengeManager: ChallengeManagerProtocol, ObservableObject {
    static let shared = ChallengeManager()

    @Published private(set) var currentUser: User?
    @Published private(set) var challenges: [Challenge] = []
    @Published private(set) var posts: [String: [ChallengePost]] = [:]

    private var cancellables = Set<AnyCancellable>()

    private let challengeService: ChallengeService
    private let userManager: UserManager
    private let accountManager: AccountManager
    private let notificationService: NotificationService
    private let rewardService: RewardService
    private let scoringService: ScoringServiceProtocol
    private let alertManager: GlobalAlertManager
    private let defaults: UserDefaults
    private let chatLastReadPrefix = "challengeChatLastRead_"

    init(userManager: UserManager = UserManager.shared,
         challengeService: ChallengeService = ChallengeService.shared,
         accountManager: AccountManager = AccountManager(),
         notifificationService: NotificationService = NotificationService.shared,
         rewardService: RewardService = RewardService.shared,
         scoringService: ScoringServiceProtocol = ScoringService.shared,
         alertManager: GlobalAlertManager = GlobalAlertManager.shared,
         defaults: UserDefaults = .standard) {
        self.userManager = userManager
        self.challengeService = challengeService
        self.accountManager = accountManager
        self.notificationService = notifificationService
        self.rewardService = rewardService
        self.scoringService = scoringService
        self.alertManager = alertManager
        self.defaults = defaults

        observeCurrentUser()
    }
}

// MARK: - Challenges
extension ChallengeManager {
    func createChallenge(_ challenge: Challenge) async throws -> Challenge? {
        do {
            let newChallenge = try await challengeService.addChallenge(challenge)
            try await self.fetchAndFilterChallenges()

            return newChallenge
        }
    }

    /// Récupère tous les défis présents dans Firestore sans filtrage
    func fetchAllChallenges() async throws -> [Challenge] {
        return try await challengeService.fetchAllChallenges()
    }

    /// Récupère tous les défis, puis filtre ceux liés à l'utilisateur courant
    func fetchAndFilterChallenges() async throws {
        guard let currentUser, let currentUserId = currentUser.id else { return }

        let filtered = try await fetchAllChallenges().filter { challenge in
            challenge.creatorUID == currentUserId || challenge.participantUids.contains(currentUserId)
        }

        await MainActor.run {
            self.challenges = filtered
            print("✅ Défis filtrés pour \(currentUser.name):", filtered.map(\.title))
        }
    }

    func ensureMembership(in challengeId: String) async throws {
        if challenges.contains(where: { $0.id == challengeId }) {
            try await fetchAndFilterChallenges()
            return
        }

        guard let currentUser, let userId = currentUser.id else {
            throw ChallengeManagerError.userNotLoggedIn
        }

        guard var remoteChallenge = try await challengeService.fetchChallenge(by: challengeId) else {
            throw ChallengeManagerError.challengeNotFound
        }

        if remoteChallenge.participantUids.contains(userId) {
            try await updateChallenge(remoteChallenge)
        } else {
            remoteChallenge.participantUids.append(userId)
            try await joinChallenge(remoteChallenge, userId: userId)
        }
    }

    func joinChallenge(withCode code: String) async throws -> Challenge {
        guard let currentUser, let userId = currentUser.id else {
            throw ChallengeManagerError.userNotLoggedIn
        }

        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty else {
            throw ChallengeManagerError.challengeNotFound
        }

        guard var remoteChallenge = try await challengeService.fetchChallenge(byCode: trimmedCode) else {
            throw ChallengeManagerError.challengeNotFound
        }

        if !remoteChallenge.participantUids.contains(userId) {
            remoteChallenge.participantUids.append(userId)
            try await joinChallenge(remoteChallenge, userId: userId)
        } else {
            try await fetchAndFilterChallenges()
        }

        return remoteChallenge
    }

    func deleteChallenge(_ challengeId: String) async throws {
        try await challengeService.deleteChallenge(challengeId: challengeId)

        await MainActor.run {
            self.challenges.removeAll { $0.id == challengeId }
            self.posts[challengeId] = nil
        }
    }

    func joinChallenge(_ challenge: Challenge, userId: String) async throws {
        try await updateChallenge(challenge)
        try await createNewParticipantProgress(userId: userId, challenge: challenge)
    }

    // Challenges - Privates

    private func updateChallenge(_ challenge: Challenge) async throws {
        try await challengeService.updateChallenge(challenge)
        try await fetchAndFilterChallenges()

        await MainActor.run {
            if let index = challenges.firstIndex(where: { $0.id == challenge.id }) {
                challenges[index] = challenge
            }
        }
    }
}

// MARK: - Chat
extension ChallengeManager {
    func fetchChatMessages(for challengeId: String) async throws -> [ChallengeChatMessage] {
        try await challengeService.fetchChatMessages(for: challengeId)
    }

    func sendChatMessage(_ content: String, challengeId: String) async throws {
        guard let currentUser, let userId = currentUser.id else { return }

        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        let message = ChallengeChatMessage(
            documentId: nil,
            challengeId: challengeId,
            senderId: userId,
            senderName: currentUser.name,
            content: trimmedContent,
            createdAt: Date(),
            reactions: [:]
        )

        try await challengeService.addChatMessage(message, to: challengeId)
    }

    func markChatAsRead(for challengeId: String) {
        defaults.set(Date(), forKey: chatLastReadPrefix + challengeId)
    }

    func hasUnreadMessages(for challengeId: String, latestMessageDate: Date?) -> Bool {
        guard let latestMessageDate else { return false }

        let lastRead = defaults.object(forKey: chatLastReadPrefix + challengeId) as? Date ?? .distantPast
        return latestMessageDate > lastRead
    }

    func addChatReaction(_ reaction: String,
                         to message: ChallengeChatMessage,
                         challengeId: String,
                         userId: String) async throws {
        guard let messageId = message.documentId else { return }

        try await challengeService.addReaction(reaction,
                                               to: messageId,
                                               in: challengeId,
                                               userId: userId)
    }

    func removeChatReaction(_ reaction: String,
                            from message: ChallengeChatMessage,
                            challengeId: String,
                            userId: String) async throws {
        guard let messageId = message.documentId else { return }

        try await challengeService.removeReaction(reaction,
                                                  from: messageId,
                                                  in: challengeId,
                                                  userId: userId)
    }
}

// MARK: - Posts
extension ChallengeManager {
    func sendPostAndNotify(media: ChallengeRawMedia, challenge: Challenge, descriptionText: String?) async throws {
        guard let currentUser, let currentUserId = currentUser.id else { return }

        print("📤 Upload du post en cours...")
        let uploadedPost = try await uploadPostToFirebase(media: media,
                                                          challengeId: challenge.id,
                                                          author: currentUser,
                                                          description: descriptionText)

        print("✅ Upload réussi, mise à jour progression Firestore...")
        try await updateParticipantProgress(for: challenge.id, userId: currentUserId, date: Date())

        triggerScoring(for: uploadedPost, in: challenge)

        await notificationService.sendPostNotification(challenge: challenge,
                                                        authorName: currentUser.name,
                                                        postId: uploadedPost.id)
    }

    func loadPosts(from challengeId: String) async throws -> [ChallengePost] {
        return try await challengeService.fetchPosts(for: challengeId)
    }

    func deletePost(_ post: ChallengePost) async throws {
        try await challengeService.deletePost(post)

        // Mise à jour du cache local
        if let thumbnailImageUrl = post.media.thumbnailImageUrl {
            ImageCache.shared.delete(forKey: thumbnailImageUrl)
        }
        self.posts[post.challengeId]?.removeAll { $0.id == post.id }
    }

    func likePost(post: ChallengePost) async throws {
        guard let currentUser, let currentUserId = currentUser.id else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            challengeService.likePost(challengeId: post.challengeId, postId: post.id, userId: currentUserId) { error in
                if let error {
                    print("❌ Like failed: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ Post likée !")
                    continuation.resume()
                }
            }
        }

        guard let challenge = self.challenges.first(where: { $0.id == post.challengeId }) else { return }

        await self.notificationService.sendLikeNotification(to: post.authorUid,
                                                            from: currentUser.name,
                                                            challenge: challenge,
                                                            postId: post.id)
    }

    func unlikePost(post: ChallengePost) async throws {
        guard let currentUser, let currentUserId = currentUser.id else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            challengeService.unlikePost(challengeId: post.challengeId, postId: post.id, userId: currentUserId) {
                error in
                if let error {
                    print("❌ Unliking post failed: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ Post unliked !")
                    continuation.resume()
                }
            }
        }
    }

    func commentPost(post: ChallengePost, content: String) async throws {
        guard let currentUser, let currentUserId = currentUser.id else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            challengeService.addComment(postId: post.id,
                                        content: content,
                                        challengeId: post.challengeId,
                                        userId: currentUserId,
                                        userName: currentUser.name) { error in
                if let error = error {
                    print("❌ Adding comment failed: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ Comment added !")
                    continuation.resume()
                }
            }
        }

        guard let challenge = self.challenges.first(where: { $0.id == post.challengeId }) else { return }

        await notificationService.sendCommentNotification(to: post.authorUid,
                                                          from: currentUser.name,
                                                          challenge: challenge,
                                                          commentText: content,
                                                          postId: post.id)
    }

    // Posts - Privates

    private func uploadPostToFirebase(media: ChallengeRawMedia, challengeId: String, author: User, description: String? = "") async throws -> ChallengePost {
        let post = try await challengeService.uploadPost(rawMedia: media,
                                                         challengeId: challengeId,
                                                         author: author,
                                                         description: description)

        await MainActor.run {
            savePostInLocal(post, to: challengeId)
        }

        return post
    }

    private func savePostInLocal(_ post: ChallengePost, to challengeId: String) {
        posts[challengeId, default: []].append(post)
    }

    private func triggerScoring(for post: ChallengePost, in challenge: Challenge) {
        Task {
            do {
                try await scoringService.enqueueScoreEntry(for: post, in: challenge)

                // ✅ on process les pending (celle que tu viens d’ajouter est pending)
                await scoringService.processPendingEntries(limit: 5)

                // ✅ ping UI
                NotificationCenter.default.post(name: .scoresDidUpdate, object: challenge.id)

            } catch {
                print("❌ [Scoring] \(error)")
            }
        }
    }
}

// MARK: - Scores
extension ChallengeManager {
    func fetchPostScoreCards(for challengeId: String, postIds: [String]) async throws -> [String: ScoreCard] {
        try await scoringService.fetchScoreCards(for: challengeId, postIds: postIds)
    }

    func fetchScoreLeaderboard(for challengeId: String,
                               granularity: ScoreAggregation.Granularity) async throws -> [ScoreAggregation] {
        try await scoringService.fetchAggregations(for: challengeId, granularity: granularity)
    }
}

// MARK: - Reward flow
extension ChallengeManager {
    func createNewParticipantProgress(userId: String, challenge: Challenge) async throws {
        let totalJokers = challenge.jokerConfiguration?.jokersPerParticipant ?? 0
        let jokerProgress = ParticipantJokerProgress(total: totalJokers)

        let userProgress = ParticipantProgress(id: userId,
                                               joinedDate: Date(),
                                               validatedDays: [],
                                               medals: [],
                                               currentStreak: 0,
                                               jokerProgress: jokerProgress)

        try setUserProgress(userId: userId, challengeId: challenge.id, progress: userProgress)
    }
    func fetchParticipantsProgress(for challengeId: String) async throws -> [ParticipantProgress] {
        var progresses = try await challengeService.fetchParticipantsProgress(for: challengeId)


        let resolvedChallenge: Challenge
        if let local = challenge(for: challengeId) {
            resolvedChallenge = local
        } else if let fetched = try await fetchChallenge(by: challengeId) {
            resolvedChallenge = fetched
        } else {
            // si le challenge n'existe plus, on renvoie juste les progresses
            return progresses
           
            // throw ChallengeManagerError.challengeNotFound
        }

        // Étape 2 : auto-déclaration pour le user courant
        if let currentUserId = currentUser?.id,
           let index = progresses.firstIndex(where: { $0.id == currentUserId }),
           let updatedProgress = await autoDeclareMissedDayIfNeeded(
                for: resolvedChallenge,
                progress: progresses[index]
           ) {
            progresses[index] = updatedProgress
        }

        return progresses
    }

    func updateParticipantProgress(for challengeId: String, userId: String, date: Date) async throws {
        do {
            print("📥 updateProgress lancé pour userId=\(userId), challengeId=\(challengeId)")
            guard var progress = try await fetchProgress(challengeId: challengeId, userId: userId) else { return }

            if progress.jokerProgress == nil {
                let total = challenge(for: challengeId)?.jokerConfiguration?.jokersPerParticipant ?? 0
                progress.jokerProgress = ParticipantJokerProgress(total: total)
            }

            guard shouldAppendDay(progress: progress, day: date) else {
                print("🔁 Journée déjà validée pour \(date)")
                return
            }

            progress.validatedDays.append(date)
            progress.currentStreak = calculateStreak(from: progress.validatedDays)
            print("✅ Nouvelle journée ajoutée. Streak actuel: \(progress.currentStreak)")

            let newMedals = detectNewMedals(from: progress, challengeId: challengeId)
            progress.medals.append(contentsOf: newMedals)

            await rewardService.persistProgress(progress, for: challengeId)
            await rewardService.addMedals(to: userId, medals: newMedals)

            _ = try await accountManager.updateCurrentUser(with: userId)

            for medal in newMedals {
                await MainActor.run {
                    alertManager.show(medal: medal, challengeId: challengeId)
                    triggerLocalNotification(for: medal)
                }
            }
        } catch {
            print("❌ updateProgress > Erreur fetch: \(error)")
        }
    }

    func assignCreationMedalsToUser(_ userId: String) async {
        let createdCount = challenges.filter { $0.creatorUID == userId }.count
        await rewardService.assignCreationMedals(to: userId, createdCount: createdCount)
    }

    func declareJokerUsage(for challenge: Challenge, on date: Date, postId: String?) async throws {
        guard let currentUser,
              let currentUserId = currentUser.id,
              (challenge.jokerConfiguration?.jokersPerParticipant ?? 0) > 0 else { return }

        let voters = [currentUserId]

        if let postId {
            let state = PostJokerState(declaredByAuthor: true,
                                        voters: voters,
                                        isConfirmed: true,
                                        confirmedAt: Date())
            try await challengeService.updatePostJokerState(challengeId: challenge.id,
                                                            postId: postId,
                                                            state: state)
        }

        try await consumeJoker(for: currentUserId,
                               in: challenge,
                               on: date,
                               postId: postId,
                               declaredByAuthor: true,
                               voters: voters)
    }

    func autoDeclareMissedDayIfNeeded(for challenge: Challenge,
                                      progress: ParticipantProgress) async -> ParticipantProgress? {
        guard let currentUserId = currentUser?.id,
              currentUserId == progress.id,
              (challenge.jokerConfiguration?.jokersPerParticipant ?? 0) > 0 else { return nil }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let targetDay = calendar.date(byAdding: .day, value: -1, to: today) else { return nil }

        let startBoundary = calendar.startOfDay(for: max(challenge.startDate, progress.joinedDate))
        let endBoundary = calendar.startOfDay(for: challenge.lastDayDate)

        guard targetDay >= startBoundary, targetDay <= endBoundary else { return nil }

        let hasValidatedDay = progress.validatedDays.contains { calendar.isDate($0, inSameDayAs: targetDay) }

        var jokerProgress = progress.jokerProgress
            ?? ParticipantJokerProgress(total: challenge.jokerConfiguration?.jokersPerParticipant ?? 0)

        let alreadyUsedJokerForDay = jokerProgress.confirmedUsages.contains { usage in
            calendar.isDate(usage.date, inSameDayAs: targetDay)
        }

        guard !hasValidatedDay, !alreadyUsedJokerForDay, jokerProgress.remaining > 0 else { return nil }

        do {
            try await consumeJoker(for: currentUserId,
                                   in: challenge,
                                   on: targetDay,
                                   postId: nil,
                                   declaredByAuthor: true,
                                   voters: [currentUserId])

            return try await fetchProgress(challengeId: challenge.id, userId: currentUserId)
        } catch {
            print("❌ Impossible d'attribuer automatiquement un joker : \(error)")
            return nil
        }
    }

    func toggleJokerVote(for post: ChallengePost, currentState: PostJokerState) async throws {
        guard let currentUser, let currentUserId = currentUser.id else { return }

        let resolvedChallenge: Challenge
        if let localChallenge = challenge(for: post.challengeId) {
            resolvedChallenge = localChallenge
        } else if let fetchedChallenge = try? await fetchChallenge(by: post.challengeId) {
            resolvedChallenge = fetchedChallenge
        } else {
            return
        }

        guard (resolvedChallenge.jokerConfiguration?.jokersPerParticipant ?? 0) > 0 else { return }

        let latestState = try await challengeService.fetchPost(challengeId: post.challengeId, postId: post.id)?.jokerState
        var state = latestState ?? currentState

        if state.isConfirmed {
            print("ℹ️ Joker déjà confirmé pour ce post")
            return
        }

        if state.voters.contains(currentUserId) {
            print("ℹ️ L'utilisateur a déjà voté pour ce joker")
            return
        }

        state.voters.append(currentUserId)

        let eligibleVoters = max(resolvedChallenge.participantUids.count - 1, 1)
        let requiredVotes = eligibleVoters <= 2 ? eligibleVoters : (eligibleVoters / 2 + 1)
        let isConfirmed = state.voters.count >= requiredVotes

        state.isConfirmed = isConfirmed
        state.confirmedAt = isConfirmed ? Date() : nil

        try await challengeService.updatePostJokerState(challengeId: post.challengeId,
                                                        postId: post.id,
                                                        state: state)

        if isConfirmed {
            try await consumeJoker(for: post.authorUid,
                                   in: resolvedChallenge,
                                   on: post.date,
                                   postId: post.id,
                                   declaredByAuthor: state.declaredByAuthor,
                                   voters: state.voters)
        }
    }

    // Reward flow - Privates

    private func setUserProgress(userId: String, challengeId: String, progress: ParticipantProgress) throws {
        return try challengeService.setUserProgress(userId: userId, challengeId: challengeId, progress: progress)
    }

    private func fetchProgress(challengeId: String, userId: String) async throws -> ParticipantProgress? {
        return try await challengeService.fetchProgress(challengeId: challengeId, userId: userId)
    }

    private func challenge(for id: String) -> Challenge? {
        challenges.first { $0.id == id }
    }

    private func fetchChallenge(by id: String) async throws -> Challenge? {
        try await challengeService.fetchAllChallenges().first(where: { $0.id == id })
    }

    private func shouldAppendDay(progress: ParticipantProgress, day: Date) -> Bool {
        !progress.validatedDays.contains { Calendar.current.isDate($0, inSameDayAs: day) }
    }

    private func detectNewMedals(from progress: ParticipantProgress, challengeId: String) -> [UserMedal] {
        let sortedCount = progress.validatedDays.count
        var medals: [UserMedal] = []

        if sortedCount == 1 && !progress.medals.contains(where: { $0.name == "🚀 Premier jour" }) {
            print("🥇 Ajout médaille: Premier jour")
            medals.append(UserMedal(name: "🚀 Premier jour",
                                    description: "Première validation !",
                                    iconName: "rocket-pencil",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak == 3 && !progress.medals.contains(where: { $0.name == "🔥 3 jours" }) {
            print("🥈 Ajout médaille: 3 jours")
            medals.append(UserMedal(name: "🔥 3 jours",
                                    description: "3 jours validés d'affilée",
                                    iconName: "apple",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak == 5 && !progress.medals.contains(where: { $0.name == "🥉 5 jours" }) {
            medals.append(UserMedal(name: "🥉 5 jours",
                                    description: "5 jours validés d'affilée",
                                    iconName: "bronze",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak == 7 && !progress.medals.contains(where: { $0.name == "🎖️ 7 jours" }) {
            medals.append(UserMedal(name: "🎖️ 7 jours",
                                    description: "7 jours validés d'affilée",
                                    iconName: "green",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak == 10 && !progress.medals.contains(where: { $0.name == "🧨 10 jours" }) {
            medals.append(UserMedal(name: "🧨 10 jours",
                                    description: "10 jours validés d'affilée",
                                    iconName: "apple",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }



        if progress.currentStreak == 14 && !progress.medals.contains(where: { $0.name == "🥈 14 jours" }) {
            medals.append(UserMedal(name: "🥈 14 jours",
                                    description: "14 jours de suite !",
                                    iconName: "silver",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }
        if progress.currentStreak == 21 && !progress.medals.contains(where: { $0.name == " 🥇21 jours" }) {
            medals.append(UserMedal(name: "🥇21 jours",
                                    description: "21 jours de suite !",
                                    iconName: "gold",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak == 25 && !progress.medals.contains(where: { $0.name == " 25 jours" }) {
            medals.append(UserMedal(name: "25 jours",
                                    description: "21 jours de suite !",
                                    iconName: "boxing",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if let challenge = challenges.first(where: { $0.id == challengeId }),
           sortedCount >= challenge.duration,
           !progress.medals.contains(where: { $0.name == "🏁 🥇Terminé" }) {
            medals.append(UserMedal(name: "🏁 🥇Terminé",
                                    description: "Défi complété",
                                    iconName: "flag",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        return medals
    }

    private func consumeJoker(for userId: String,
                              in challenge: Challenge,
                              on date: Date,
                              postId: String?,
                              declaredByAuthor: Bool,
                              voters: [String]) async throws {
        var progress = try await fetchProgress(challengeId: challenge.id, userId: userId)

        if progress == nil {
            print("⚠️ Aucune progression trouvée pour \(userId), initialisation d'un suivi avec jokers par défaut")

            let jokerTotal = challenge.jokerConfiguration?.jokersPerParticipant ?? 0
            let newProgress = ParticipantProgress(id: userId,
                                                  joinedDate: Date(),
                                                  validatedDays: [],
                                                  medals: [],
                                                  currentStreak: 0,
                                                  jokerProgress: ParticipantJokerProgress(total: jokerTotal))

            try setUserProgress(userId: userId, challengeId: challenge.id, progress: newProgress)
            progress = newProgress
        }

        guard var progress else { return }

        var jokerProgress = progress.jokerProgress
            ?? ParticipantJokerProgress(total: challenge.jokerConfiguration?.jokersPerParticipant ?? 0)

        let alreadyRecorded = postId != nil && (jokerProgress.usages.contains { $0.postId == postId })

        if !alreadyRecorded && jokerProgress.remaining <= 0 {
            print("⚠️ Aucun joker restant pour l'utilisateur \(userId)")
            return
        }

        jokerProgress.registerConfirmedUsage(on: date,
                                             postId: postId,
                                             declaredByAuthor: declaredByAuthor,
                                             voters: voters)

        progress.jokerProgress = jokerProgress

        if shouldAppendDay(progress: progress, day: date) {
            progress.validatedDays.append(date)
        }

        progress.currentStreak = calculateStreak(from: progress.validatedDays)

        let newMedals = detectNewMedals(from: progress, challengeId: challenge.id)
        if !newMedals.isEmpty {
            progress.medals.append(contentsOf: newMedals)
        }

        await rewardService.persistProgress(progress, for: challenge.id)

        if !newMedals.isEmpty {
            await rewardService.addMedals(to: userId, medals: newMedals)
        }

        if declaredByAuthor, currentUser?.id == userId {
            _ = try? await accountManager.updateCurrentUser(with: userId)
        }

        if !declaredByAuthor, let postId {
            await notificationService.sendJokerConsumedNotification(to: userId,
                                                                    challenge: challenge,
                                                                    postId: postId,
                                                                    remainingJokers: jokerProgress.remaining)
        }

        if !newMedals.isEmpty {
            for medal in newMedals {
                await MainActor.run {
                    alertManager.show(medal: medal, challengeId: challenge.id)
                    triggerLocalNotification(for: medal)
                }
            }
        }
    }

    private func triggerLocalNotification(for medal: UserMedal) {
        let content = UNMutableNotificationContent()

        content.title = "🎖️ Nouvelle médaille débloquée!"
        content.body = "\(medal.name): \(medal.description)"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func calculateStreak(from dates: [Date]) -> Int {
        let sorted = dates.sorted(by: >)
        guard let mostRecentDay = sorted.first else { return 0 }

        var streak = 0

        for date in sorted {
            let expectedDate = Calendar.current.date(byAdding: .day, value: -streak, to: mostRecentDay) ?? date

            if Calendar.current.isDate(date, inSameDayAs: expectedDate) {
                streak += 1
            } else {
                break
            }
        }
        print("🔢 Calcul streak depuis:", dates)

        return streak
    }
}

// MARK: - Notifications
extension ChallengeManager {
    func updateNotifications(for challenge: Challenge,
                             config: [ChallengeNotification],
                             completion: ((Error?) -> Void)? = nil) {
        // Mise à jour locale dans la liste
        if let idx = self.challenges.firstIndex(where: { $0.id == challenge.id }) {
            self.challenges[idx].notificationsConfig = config
        }


        // Mise à jour Firestore via service
        challengeService.updateNotifications(for: challenge, config: config) { error in
            if let error = error {
                print("❌ Erreur lors de l’envoi vers Firestore : \(error)")
            } else {
                print("✅ Notifications mises à jour dans Firestore")
            }
            completion?(error)
        }

        // ✅ MAJ l’objet challenge pour l’appel à NotificationManager
        var updatedChallenge = challenge
        updatedChallenge.notificationsConfig = config

        NotificationManager.shared.scheduleAllNotifications(for: updatedChallenge)

        print("🛠 updateNotifications called with \(config.count) configs for challenge \(challenge.title)")
    }
}

// MARK: - Observers
extension ChallengeManager {
    private func observeCurrentUser() {
             userManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentUser in
                self?.currentUser = currentUser

                if let uid = currentUser?.id, !uid.isEmpty {
                    OneSignal.login(uid)

                    // 🔄 si déjà présent, on persiste; sinon on attend 1s
                    if let _ = OneSignal.User.pushSubscription.id {
                        NotificationService.shared.setOneSignalPushId(to: uid)
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            NotificationService.shared.setOneSignalPushId(to: uid)
                        }
                    }
                } else {
                    OneSignal.logout()
                }
            }
            .store(in: &cancellables)
    }
}
extension Notification.Name {
    static let scoresDidUpdate = Notification.Name("scoresDidUpdate")
}
