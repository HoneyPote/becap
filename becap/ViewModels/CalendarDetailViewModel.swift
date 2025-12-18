//
//  CalendarDetailViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

struct ParticipantUIModel: Hashable {
    let userId: String
    let userName: String
    let userMedals: [UserMedal]
    let userProfilePhotoURL: String?
    let progress: ParticipantProgress
    let posts: [ChallengePost]

    var isAdmin: Bool

    static func == (lhs: ParticipantUIModel, rhs: ParticipantUIModel) -> Bool {
        lhs.userId == rhs.userId && lhs.userName == rhs.userName
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
        hasher.combine(userName)
    }
}

struct ParticipantProgress: Identifiable, Codable {
    var id: String {
        userId
    }

    var userId: String
    var validatedDays: [Date]
    var currentStreak: Int
    var jokerProgress: ParticipantJokerProgress
    var medals: [UserMedal]

    let challengeId: String
    let joinedDate: Date
    let isCreator: Bool
    let isBlocked: Bool
}

struct CalendarDayJokerUsage: Identifiable, Hashable {
    let id: String
    let participantId: String
    let participantName: String
    let participantPhotoURL: String?
    let declaredByAuthor: Bool
    let voterIds: [String]
    let voterNames: [String]
    let postId: String?

    var voteCount: Int { voterIds.count }
}

struct CalendarDetailCell: Hashable,Identifiable {
    var date: Date
    var posts: [ChallengePost]
    var jokers: [CalendarDayJokerUsage]
    var premiumAttachments: [PremiumCalendarAttachment]
    var isToday: Bool

    var id: Date { date }
}

class CalendarDetailViewModel: ObservableObject {
    @Published var allPosts: [ChallengePost] = []
    @Published var detailCells: [CalendarDetailCell]?
    @Published var doneLoadingPosts: Bool = false
    @Published var selectedPagerInfo: PagerInfo?
    @Published var participants: [ParticipantUIModel] = []
    @Published var participantProgresses: [ParticipantProgress] = []
    @Published var chatMessages: [ChallengeChatMessage] = []
    @Published var chatHasUnreadMessages: Bool = false
    @Published var premiumAttachments: [PremiumCalendarAttachment] = []
    @Published var isSavingPremiumContent: Bool = false

    private var allCells: [CalendarDetailCell] = []

    private let accountManager: AccountManager
    private let challengeManager: ChallengeManager

    @Published private(set) var challenge: Challenge

    init(accountManager: AccountManager = AccountManager(),
         challengeManager: ChallengeManager = ChallengeManager.shared,
         challenge: Challenge) {
        self.accountManager = accountManager
        self.challengeManager = challengeManager
        self.challenge = challenge
        self.premiumAttachments = challenge.premiumAttachments ?? []
    }

    func fetchInfos() {
        self.doneLoadingPosts = false

        Task {
            async let postsTask = try fetchPosts()
            async let progressesTask = try fetchParticipantProgresses()
            async let chatTask = try fetchChatMessages()

            let (posts, progresses, chatMessages) = try await (postsTask, progressesTask, chatTask)

            let allParticipants = try await buildParticipants(from: progresses, allPosts: posts)

            await MainActor.run {
                guard let progresses, !allParticipants.isEmpty else {
                    self.doneLoadingPosts = true
                    return
                }
                self.updatePosts(posts)
                self.participants = allParticipants
                self.participantProgresses = progresses
                self.updateHasUnreadMessages(messages: chatMessages)
                self.allCells = self.buildDetailcells()
                self.premiumAttachments = self.challenge.premiumAttachments ?? []
                self.doneLoadingPosts = true
            }
        }
    }

    // MARK: - Premium attachments
    var canEditPremiumContent: Bool {
        (challenge.isPremium ?? false)
        && challenge.creatorUID == challengeManager.currentUser?.id
        && (challengeManager.currentUser?.isInfluencer ?? false)
    }

    func attachments(for dayIndex: Int) -> [PremiumCalendarAttachment] {
        premiumAttachments.filter { $0.dayIndex == dayIndex }
    }

    func attachmentCountByDay() -> [Date: Int] {
        var counts: [Date: Int] = [:]
        let calendar = Calendar.current

        for attachment in premiumAttachments {
            let offset = attachment.dayIndex - 1
            guard offset >= 0,
                  let date = calendar.date(byAdding: .day, value: offset, to: challenge.startDate) else { continue }

            let key = calendar.startOfDay(for: date)
            counts[key, default: 0] += 1
        }

        return counts
    }

    func addAttachment(data: Data, title: String, kind: PremiumAttachmentKind, dayIndex: Int, fileExtension: String? = nil) async {
        do {
            let savedName = try persist(data: data, kind: kind, fileExtension: fileExtension)
            let attachment = PremiumCalendarAttachment(dayIndex: dayIndex,
                                                       title: title,
                                                       fileName: savedName,
                                                       kind: kind)

            await MainActor.run {
                premiumAttachments.append(attachment)
            }

            try await savePremiumAttachments()
        } catch {
            debugPrint("❌ Failed to store premium attachment: \(error.localizedDescription)")
        }
    }

    func removeAttachment(_ attachment: PremiumCalendarAttachment) async {
        await MainActor.run {
            premiumAttachments.removeAll { $0.id == attachment.id }
        }

        if let url = attachment.localFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        try? await savePremiumAttachments()
    }

    @discardableResult
    func savePremiumAttachments() async throws -> Challenge {
        guard canEditPremiumContent else { return challenge }

        await MainActor.run { isSavingPremiumContent = true }

        var updated = challenge
        updated.premiumAttachments = premiumAttachments

        do {
            let persisted = try await challengeManager.savePremiumAttachments(updated)
            await MainActor.run {
                self.challenge = persisted
                self.premiumAttachments = persisted.premiumAttachments ?? []
                self.isSavingPremiumContent = false
            }

            return persisted
        } catch {
            await MainActor.run { isSavingPremiumContent = false }
            throw error
        }
    }

    func canDeletePost(posts: [ChallengePost]) -> Bool {
        guard let currentUser = challengeManager.currentUser, let currentUserId = currentUser.id else { return false }

        return posts.first?.authorUid == currentUserId
    }

    func filterDetailCells(for selectedParticipant: ParticipantUIModel?) -> [CalendarDetailCell] {
        guard let selectedParticipant else { return allCells }

        return allCells.map { cell in
            let filteredPosts = cell.posts.filter { $0.authorUid == selectedParticipant.userId }
            let filteredJokers = cell.jokers.filter { $0.participantId == selectedParticipant.userId }

            return CalendarDetailCell(date: cell.date,
                                      posts: filteredPosts,
                                      jokers: filteredJokers,
                                      isToday: cell.isToday
            )
        }
    }

    func detailButtonClicked(cell: CalendarDetailCell) {
        if !cell.posts.isEmpty {
            buildPagerInfo(cell: cell)
        }
    }

    func jokerUsageCounts(for selectedParticipant: ParticipantUIModel? = nil) -> [Date: Int] {
        guard challenge.jokerConfiguration > 0 else { return [:] }

        let relevantProgresses: [ParticipantProgress]

        if let selectedParticipant {
            relevantProgresses = [selectedParticipant.progress]
        } else {
            relevantProgresses = participantProgresses
        }

        guard !relevantProgresses.isEmpty else { return [:] }

        var counts: [Date: Int] = [:]
        counts.reserveCapacity(relevantProgresses.count * 2)

        let calendar = Calendar.current

        for progress in relevantProgresses {
            for usage in progress.jokerProgress.confirmedUsages {
                let day = calendar.startOfDay(for: usage.date)
                counts[day, default: 0] += 1
            }
        }

        return counts
    }

    private func persist(data: Data, kind: PremiumAttachmentKind, fileExtension: String? = nil) throws -> String {
        let ext: String = {
            if let fileExtension, !fileExtension.isEmpty {
                return fileExtension
            }
            return kind == .pdf ? "pdf" : "dat"
        }()

        let fileName = "premium_\(UUID().uuidString).\(ext)"
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw URLError(.fileDoesNotExist)
        }

        let destination = documentsURL.appendingPathComponent(fileName)
        try data.write(to: destination, options: .atomic)

        return fileName
    }

    func deletePost(_ postId: String) {
        self.allPosts.removeAll(where: { $0.id == postId })
    }

    func getParticipant(for uid: String) -> ParticipantUIModel? {
        participants.first(where: { $0.userId == uid })
    }

    var currentUserId: String? {
        challengeManager.currentUser?.id
    }

    var currentUserProgress: ParticipantProgress? {
        guard let currentUserId else { return nil }

        return participantProgresses.first(where: { $0.userId == currentUserId })
    }

    var currentUserJokerStatus: (total: Int, remaining: Int)? {
        let total = challenge.jokerConfiguration

        guard let progress = currentUserProgress else {
            guard total > 0 else { return nil }
            return (total, total)
        }

        guard total > 0 else { return nil }
        let remaining = progress.jokerProgress.remaining
        return (total, remaining)
    }

    var canUseJokerToday: Bool {
        guard let status = currentUserJokerStatus else { return false }
        guard status.remaining > 0 else { return false }

        guard let progress = currentUserProgress else { return true }

        let today = Calendar.current.startOfDay(for: Date())
        let hasValidatedToday = progress.validatedDays.contains { Calendar.current.isDate($0, inSameDayAs: today) }

        return !hasValidatedToday
    }

    func useJokerForToday() {
        guard canUseJokerToday, let currentUserProgress else { return }

        Task {
            do {
                try await challengeManager.autoDeclareDailyJoker(for: currentUserProgress)

                await MainActor.run {
                    self.fetchInfos()
                }
            } catch {
                print("❌ Failed to declare joker for today: \(error)")
            }
        }
    }

    // MARK: - Private functions

    private func buildParticipants(from participantProgresses: [ParticipantProgress]?,
                                   allPosts: [ChallengePost]) async throws -> [ParticipantUIModel] {
        guard let participantProgresses, let currentUser = challengeManager.currentUser else { return [] }

        var allParticipants: [ParticipantUIModel] = []

        for progress in participantProgresses {
            guard let user = try await accountManager.fetchUser(uid: progress.id),
                  let userId = user.id
            else { continue }

            let participantName = currentUser.id == user.id ? "\(user.name) (moi)" : user.name
            let isAdmin = challenge.adminUids.contains(where: { $0 == userId })
            let posts = allPosts.filter { $0.authorUid == userId }

            let newParticipant = ParticipantUIModel(userId: userId,
                                                    userName: participantName,
                                                    userMedals: user.medals,
                                                    userProfilePhotoURL: user.photoURL,
                                                    progress: progress,
                                                    posts: posts,
                                                    isAdmin: isAdmin)

            allParticipants.append(newParticipant)
        }

        return allParticipants
    }

    private func buildDetailcells() -> [CalendarDetailCell] {
        let calendar = Calendar.current

        let postsByDay: [Date: [ChallengePost]] = Dictionary(grouping: allPosts) {
            calendar.startOfDay(for: $0.date)
        }

        let participantMap = Dictionary(uniqueKeysWithValues: participants.map { ($0.userId, $0) })

        var jokersByDay: [Date: [CalendarDayJokerUsage]] = [:]
        jokersByDay.reserveCapacity(challenge.duration)

        for progress in participantProgresses {
            guard let participant = participantMap[progress.userId] else { continue }

            for usage in progress.jokerProgress.confirmedUsages {
                let day = calendar.startOfDay(for: usage.date)
                let joker = CalendarDayJokerUsage(id: usage.id,
                                                  participantId: progress.userId,
                                                  participantName: participant.userName,
                                                  participantPhotoURL: participant.userProfilePhotoURL,
                                                  declaredByAuthor: usage.declaredByAuthor,
                                                  voterIds: usage.voters,
                                                  voterNames: usage.voters.compactMap { participantMap[$0]?.userName },
                                                  postId: usage.postId)
                jokersByDay[day, default: []].append(joker)
            }
        }

        return (0..<challenge.duration).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: challenge.startDate) else {
                return nil
            }
            let day = calendar.startOfDay(for: date)

            let posts = postsByDay[day] ?? []
            let jokers = (jokersByDay[day] ?? []).sorted { $0.participantName < $1.participantName }

            return CalendarDetailCell(date: date,
                                      posts: posts,
                                      jokers: jokers,
                                      isToday: calendar.isDateInToday(date))
        }
    }

    private func fetchParticipantProgresses() async throws -> [ParticipantProgress]? {
        let allProgresses = try await challengeManager.fetchParticipantsProgress(for: challenge.id)

        guard let allProgresses,
              let currentUserProgress = allProgresses.first(where: { $0.id == currentUserId })
        else { return nil }

        // When entering calendar view we update current user progress with autodeclared missed days jokers
        let updatedUserProgress = await challengeManager.autoDeclareMissedDayJokers(for: challenge, progress: currentUserProgress)

        // Deleting old current user progress and positionning the updated one at the begining of the progresses array
        var newAllProgresses = allProgresses
        guard let updatedUserProgress,
              let index = newAllProgresses.firstIndex(where: { $0.id == currentUserId })
        else { return nil }

        newAllProgresses.remove(at: index)
        newAllProgresses.insert(updatedUserProgress, at: 0)

        return newAllProgresses
    }

    private func updateHasUnreadMessages(messages: [ChallengeChatMessage]) {
        guard let lasMessageDate = messages.last?.createdAt else { return }
        self.chatHasUnreadMessages = challengeManager.checkForUnreadMessages(for: challenge.id,
                                                                             latestMessageDate: lasMessageDate)
    }

    private func fetchChatMessages() async throws -> [ChallengeChatMessage] {
        return try await challengeManager.fetchChatMessages(for: challenge.id)
    }

    private func buildPagerInfo(cell: CalendarDetailCell) {
        selectedPagerInfo = PagerInfo(posts: cell.posts, index: 0, date: cell.date)
    }

    private func fetchPosts() async throws -> [ChallengePost] {
        return try await challengeManager.loadPosts(from: challenge.id)
    }

    private func updatePosts(_ posts: [ChallengePost]) {
        self.allPosts = posts
    }
}
