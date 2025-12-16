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
    func fetchAndFilterChallenges() async throws
    func ensureMembership(in challengeId: String) async throws
    func deleteChallenge(_ challengeId: String) async throws
    func joinChallenge(withCode code: String) async throws -> Challenge
    func removeParticipant(_ challengeId: String, userId: String) async throws

    // Posts
    func sendPostAndNotify(media: ChallengeRawMedia, challenge: Challenge, descriptionText: String?) async throws
    func loadPosts(from challengeId: String) async throws -> [ChallengePost]
    func deletePost(_ post: ChallengePost) async throws
    func likePost(post: ChallengePost) async throws
    func unlikePost(post: ChallengePost) async throws
    func commentPost(post: ChallengePost, content: String) async throws

    // Reward flow
    func createNewParticipantProgress(userId: String, challenge: Challenge) async throws
    func updateParticipantProgress(progress: ParticipantProgress) async throws -> ParticipantProgress
    func assignCreationMedalsToUser(_ userId: String) async
    func autoDeclareDailyJoker(for progress: ParticipantProgress) async throws
    func autoDeclareMissedDayJokers(for challenge: Challenge, progress: ParticipantProgress) async -> ParticipantProgress?
    func declareJokerOnPost(for post: ChallengePost, jokerState: PostJokerState) async throws

    // Notifications
    func updateNotifications(for challenge: Challenge, config: [ChallengeNotification], completion: ((Error?) -> Void)?)

    // Chat
    func fetchChatMessages(for challengeId: String) async throws -> [ChallengeChatMessage]
    func sendChatMessage(_ content: String, challengeId: String) async throws
    func markChatAsRead(for challengeId: String)
    func checkForUnreadMessages(for challengeId: String, latestMessageDate: Date) -> Bool
    func addChatReaction(_ reaction: String, to message: ChallengeChatMessage, challengeId: String, userId: String) async throws
    func removeChatReaction(_ reaction: String, from message: ChallengeChatMessage, challengeId: String, userId: String) async throws
}

enum ChallengeManagerError: LocalizedError {
    case userNotLoggedIn
    case challengeNotFound
    case progressNotUpdated
    case userSoloAdmin

    var errorDescription: String? {
        switch self {
        case .userNotLoggedIn:
            return "Vous devez être connecté pour rejoindre ce défi."
        case .challengeNotFound:
            return "Le défi partagé est introuvable ou n’existe plus."
        case .progressNotUpdated:
            return "Nous n'avons pas pu mettre à jour vos progrès"
        case .userSoloAdmin:
            return "Vous êtes seul admin de ce challenge. Vous devez promouvoir un autre utilisateur comme admin pour pouvoir quitter ce challenge."
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
    private let alertManager: GlobalAlertManager
    private let defaults: UserDefaults
    private let chatLastReadPrefix = "challengeChatLastRead_"
    private let hasUnreadMessagePrefix = "challengeHasUnreadMessage_"

    init(userManager: UserManager = UserManager.shared,
         challengeService: ChallengeService = ChallengeService.shared,
         accountManager: AccountManager = AccountManager(),
         notifificationService: NotificationService = NotificationService.shared,
         rewardService: RewardService = RewardService.shared,
         alertManager: GlobalAlertManager = GlobalAlertManager.shared,
         defaults: UserDefaults = .standard) {
        self.userManager = userManager
        self.challengeService = challengeService
        self.accountManager = accountManager
        self.notificationService = notifificationService
        self.rewardService = rewardService
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

    /// Récupère tous les défis, puis filtre ceux liés à l'utilisateur courant
    func fetchAndFilterChallenges() async throws {
        guard let currentUser, let currentUserId = currentUser.id else { return }

        let allChallenges = try await fetchAllChallenges()
        let filtered = allChallenges.filter { challenge in
            challenge.creatorUID == currentUserId || challenge.participantUids.contains(currentUserId)
        }

        // TODO: Temporary piece of code, to be removed when all the users have an existing participatingChallenges field in database
        for filter in filtered {
            try await challengeService.addParticipatingChallenge(to: currentUserId, challengeId: filter.id)

        let paywalled = allChallenges.filter { challenge in
            (challenge.isPremium ?? false)
            && challenge.creatorUID != currentUserId
            && !challenge.participantUids.contains(currentUserId)
        }

        let merged = filtered + paywalled.filter { paywalledChallenge in
            !filtered.contains(where: { $0.id == paywalledChallenge.id })
        }

        await MainActor.run {
            self.challenges = merged
            print("✅ Défis filtrés pour \(currentUser.name):", merged.map(\.title))
        }
    }

    func ensureMembership(in challengeId: String) async throws {
        if challenges.contains(where: { $0.id == challengeId }) {
            try await fetchAndFilterChallenges()
            return
        }

        guard let currentUser, let currentUserId = currentUser.id else {
            throw ChallengeManagerError.userNotLoggedIn
        }

        guard let joinedChallenge = try await challengeService.fetchChallenge(by: challengeId),
              let progresses = try await challengeService.fetchParticipantsProgress(for: joinedChallenge.id)
        else {
            throw ChallengeManagerError.challengeNotFound
        }

        let isNewToChallenge = !progresses.contains(where: { $0.userId == currentUserId })

        try await manageJoiningChallenge(joinedChallenge,
                                         currentUserId: currentUserId,
                                         isNewToChallenge: isNewToChallenge)
    }

    func joinChallenge(withCode code: String) async throws -> Challenge {
        guard let currentUser, let currentUserId = currentUser.id else {
            throw ChallengeManagerError.userNotLoggedIn
        }

        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCode.isEmpty,
              let joinedChallenge = try await challengeService.fetchChallenge(byCode: trimmedCode),
              let progresses = try await challengeService.fetchParticipantsProgress(for: joinedChallenge.id)
        else {
            throw ChallengeManagerError.challengeNotFound
        }

        let isNewToChallenge = !progresses.contains(where: { $0.userId == currentUserId })

        try await manageJoiningChallenge(joinedChallenge,
                                         currentUserId: currentUserId,
                                         isNewToChallenge: isNewToChallenge)

        return joinedChallenge
    }

    func manageJoiningChallenge(_ challenge: Challenge, currentUserId: String, isNewToChallenge: Bool) async throws {
        if isNewToChallenge {
            try await createNewParticipantProgress(userId: currentUserId, challenge: challenge)
        } else {
            try await challengeService.unblockParticipant(challengeId: challenge.id, userId: currentUserId)
        }

        try await challengeService.addParticipant(challengeId: challenge.id, userId: currentUserId)
        try await challengeService.addParticipatingChallenge(to: currentUserId, challengeId: challenge.id)
        try await fetchAndFilterChallenges()
    }

    func deleteChallenge(_ challengeId: String) async throws {
        try await challengeService.deleteChallenge(challengeId: challengeId)

        await MainActor.run {
            self.challenges.removeAll { $0.id == challengeId }
            self.posts[challengeId] = nil
        }
    }

    func removeParticipant(_ challengeId: String, userId: String) async throws {
        guard let allAdmins = try await challengeService.fetchAdminUids(for: challengeId) else { return }

        if allAdmins.contains(userId) {
            if allAdmins.count == 1 {
                throw ChallengeManagerError.userSoloAdmin
            } else {
                try await challengeService.removeAdminUid(challengeId: challengeId, uid: userId)
            }
        }

        try await challengeService.removeParticipant(challengeId: challengeId, userId: userId)
        try await challengeService.removeParticipatingChallenge(to: userId, challengeId: challengeId)
        try await challengeService.blockParticipant(challengeId: challengeId, userId: userId)
    }

    func savePremiumAttachments(_ updatedChallenge: Challenge) async throws -> Challenge {
        try await updateChallenge(updatedChallenge)
        return updatedChallenge
    }

    // Challenges - Privates

    /// Récupère tous les défis présents dans Firestore sans filtrage
    private func fetchAllChallenges() async throws -> [Challenge] {
        return try await challengeService.fetchAllChallenges()
    }

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

        let message = ChallengeChatMessage(documentId: nil,
                                           challengeId: challengeId,
                                           senderId: userId,
                                           senderName: currentUser.name,
                                           content: trimmedContent,
                                           createdAt: Date(),
                                           reactions: [:])

        try await challengeService.addChatMessage(message, to: challengeId)
    }

    func markChatAsRead(for challengeId: String) {
        defaults.set(Date(), forKey: chatLastReadPrefix + challengeId)
        defaults.set(false, forKey: hasUnreadMessagePrefix + challengeId)
    }

    func getHasUnreadMessages(for challengeId: String) -> Bool {
        defaults.bool(forKey: hasUnreadMessagePrefix + challengeId)
    }

    func checkForUnreadMessages(for challengeId: String, latestMessageDate: Date) -> Bool {
        let lastRead = defaults.object(forKey: chatLastReadPrefix + challengeId) as? Date ?? .distantPast
        defaults.set(latestMessageDate > lastRead, forKey: hasUnreadMessagePrefix + challengeId)
        return latestMessageDate > lastRead
    }

    func addChatReaction(_ reaction: String,
                         to message: ChallengeChatMessage,
                         challengeId: String,
                         userId: String) async throws {
        guard let messageId = message.documentId else { return }

        try await challengeService.addReaction(reaction, to: messageId, in: challengeId, userId: userId)
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
        let allParticipants = challenge.participantUids

        guard let currentUser,
              let currentUserId = currentUser.id,
              let progress = try await fetchProgress(challengeId: challenge.id, userId: currentUserId)
        else { return }

        let uploadedPost = try await uploadPostToFirebase(media: media,
                                                          challengeId: challenge.id,
                                                          author: currentUser,
                                                          description: descriptionText)

        var newProgress = progress
        if !dayAlreadyValidated(progress: newProgress, day: Date()) {
            newProgress.validatedDays.append(Date())
        }

        _ = try await updateParticipantProgress(progress: newProgress)

        let externalIds = Array(Set(allParticipants.filter { $0 != currentUserId }))
        if !externalIds.isEmpty {
            await notificationService.sendPostNotification(challenge: challenge,
                                                           authorName: currentUser.name,
                                                           postId: uploadedPost.id)
        }
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
}

// MARK: - Reward flow
extension ChallengeManager {
    func createNewParticipantProgress(userId: String, challenge: Challenge) async throws {
        let newUserProgress = ParticipantProgress(userId: userId,
                                                  validatedDays: [],
                                                  currentStreak: 0,
                                                  jokerProgress: ParticipantJokerProgress(total: challenge.jokerConfiguration),
                                                  medals: [],
                                                  challengeId: challenge.id,
                                                  joinedDate: Date(),
                                                  isCreator: challenge.creatorUID == userId,
                                                  isBlocked: false)

        try setUserProgress(progress: newUserProgress)
    }

    func fetchParticipantsProgress(for challengeId: String) async throws -> [ParticipantProgress]? {
        return try await challengeService.fetchParticipantsProgress(for: challengeId)
    }

    func updateParticipantProgress(progress: ParticipantProgress) async throws -> ParticipantProgress {
        do {
            let userId = progress.userId
            let challengeId = progress.challengeId

            var newProgress = progress

            newProgress.currentStreak = calculateStreak(from: newProgress.validatedDays)

            let newMedals = detectNewMedals(from: newProgress)
            newProgress.medals.append(contentsOf: newMedals)

            await rewardService.persistProgress(newProgress)
            await rewardService.addMedals(to: userId, medals: newMedals)

            _ = try await accountManager.updateCurrentUser(with: userId)

            await MainActor.run {
                for medal in newMedals {
                    alertManager.show(medal: medal, challengeId: challengeId)
                    triggerLocalNotification(for: medal)
                }
            }

            return newProgress
        } catch {
            print("❌ updateProgress > Erreur fetch: \(error)")
            throw ChallengeManagerError.progressNotUpdated
        }
    }

    func assignCreationMedalsToUser(_ userId: String) async {
        let createdCount = challenges.filter { $0.creatorUID == userId }.count
        await rewardService.assignCreationMedals(to: userId, createdCount: createdCount)
    }

    func autoDeclareDailyJoker(for progress: ParticipantProgress) async throws {
        let today = Date()

        guard let currentUser,
              let currentUserId = currentUser.id,
              !dayAlreadyValidated(progress: progress, day: today)
        else { return }

        var newProgress = progress
        let jokerUsageIsRegistered = newProgress.jokerProgress.jokerUsageIsRegistered(on: today, postId: nil, declaredByAuthor: true, voters: [currentUserId])

        if jokerUsageIsRegistered {
            newProgress.validatedDays.append(today)
        }

        await rewardService.persistProgress(newProgress)
    }

    func autoDeclareMissedDayJokers(for challenge: Challenge, progress: ParticipantProgress) async -> ParticipantProgress? {
        guard let currentUserId = currentUser?.id, currentUserId == progress.id
        else { return nil }

        let calendar = Calendar.current
        var lastValidatedDay = progress.validatedDays.max() ?? progress.joinedDate

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()),
              !calendar.isDate(lastValidatedDay, inSameDayAs: yesterday),
              challenge.jokerConfiguration > 0,
              progress.jokerProgress.remaining > 0
        else { return progress }

        let endBoundary = Date() > challenge.lastDayDate ? challenge.lastDayDate : yesterday

        var newProgress = progress
        while calendar.startOfDay(for: lastValidatedDay) <= calendar.startOfDay(for: endBoundary) {
            if !dayAlreadyValidated(progress: newProgress, day: lastValidatedDay) {
                let jokerUsageIsRegistered = newProgress.jokerProgress.jokerUsageIsRegistered(on: lastValidatedDay, postId: nil, declaredByAuthor: true, voters: [currentUserId])

                if jokerUsageIsRegistered {
                    newProgress.validatedDays.append(lastValidatedDay)
                }
            }

            lastValidatedDay = calendar.date(byAdding: .day, value: 1, to: lastValidatedDay)!
        }

        do {
            return try await updateParticipantProgress(progress: newProgress)
        } catch {
            print("❌ Impossible d'attribuer automatiquement un joker : \(error)")
            return nil
        }
    }

    func declareJokerOnPost(for post: ChallengePost, jokerState: PostJokerState) async throws {
        guard let currentUser,
              let currentUserId = currentUser.id,
              let challenge = challenge(for: post.challengeId)
        else {
            throw NSError(domain: "FetchError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de trouver le user ou le challenge associé."])
        }

        var state = jokerState
        let isAutoDeclared = currentUserId == post.authorUid

        state.voters.append(currentUserId)

        if isAutoDeclared {
            state.declaredByAuthor = true
            state.isConfirmed = true
            state.confirmedAt = Date()
        } else {
            let eligibleVoters = max(challenge.participantUids.count - 1, 1)
            let requiredVotes = eligibleVoters <= 2 ? eligibleVoters : (eligibleVoters / 2 + 1)

            if state.voters.count >= requiredVotes {
                state.isConfirmed = true
                state.confirmedAt = Date()
            }
        }

        try await challengeService.updatePostJokerState(challengeId: post.challengeId,
                                                        postId: post.id,
                                                        state: state)

        if state.isConfirmed,
           var progress = try await fetchProgress(challengeId: post.challengeId, userId: post.authorUid) {
            _ = progress.jokerProgress.jokerUsageIsRegistered(on: Date(),
                                                              postId: post.id,
                                                              declaredByAuthor: isAutoDeclared,
                                                              voters: state.voters)
            await rewardService.persistProgress(progress)

            if !isAutoDeclared {
                await notificationService.sendJokerConsumedNotification(to: post.authorUid,
                                                                        challenge: challenge,
                                                                        postId: post.id,
                                                                        remainingJokers: progress.jokerProgress.remaining)
            }
        }
    }

    // Reward flow - Privates

    private func setUserProgress(progress: ParticipantProgress) throws {
        return try challengeService.setUserProgress(progress: progress)
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

    private func dayAlreadyValidated(progress: ParticipantProgress, day: Date) -> Bool {
        progress.validatedDays.contains { Calendar.current.isDate($0, inSameDayAs: day) }
    }

    private func detectNewMedals(from progress: ParticipantProgress) -> [UserMedal] {
        let sortedCount = progress.validatedDays.count
        let challengeId = progress.challengeId
        var medals: [UserMedal] = []

        if sortedCount >= 1 && !progress.medals.contains(where: { $0.name == "🚀 Premier jour" }) {
            print("🥇 Ajout médaille: Premier jour")
            medals.append(UserMedal(name: "🚀 Premier jour",
                                    description: "Première validation !",
                                    iconName: "rocket-pencil",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak >= 3 && !progress.medals.contains(where: { $0.name == "🔥 3 jours" }) {
            print("🥈 Ajout médaille: 3 jours")
            medals.append(UserMedal(name: "🔥 3 jours",
                                    description: "3 jours validés d'affilée",
                                    iconName: "apple",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak >= 5 && !progress.medals.contains(where: { $0.name == "🥉 5 jours" }) {
            medals.append(UserMedal(name: "🥉 5 jours",
                                    description: "5 jours validés d'affilée",
                                    iconName: "bronze",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak >= 7 && !progress.medals.contains(where: { $0.name == "🎖️ 7 jours" }) {
            medals.append(UserMedal(name: "🎖️ 7 jours",
                                    description: "7 jours validés d'affilée",
                                    iconName: "green",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak >= 10 && !progress.medals.contains(where: { $0.name == "🧨 10 jours" }) {
            medals.append(UserMedal(name: "🧨 10 jours",
                                    description: "10 jours validés d'affilée",
                                    iconName: "apple",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak >= 14 && !progress.medals.contains(where: { $0.name == "🥈 14 jours" }) {
            medals.append(UserMedal(name: "🥈 14 jours",
                                    description: "14 jours de suite !",
                                    iconName: "silver",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak >= 21 && !progress.medals.contains(where: { $0.name == "🥇21 jours" }) {
            medals.append(UserMedal(name: "🥇21 jours",
                                    description: "21 jours de suite !",
                                    iconName: "gold",
                                    achievedDate: Date(),
                                    challengeId: challengeId))
        }

        if progress.currentStreak >= 25 && !progress.medals.contains(where: { $0.name == "25 jours" }) {
            medals.append(UserMedal(name: "25 jours",
                                    description: "25 jours de suite !",
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
