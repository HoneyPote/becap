//
//  CalendarDetailViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

struct Participant: Hashable {
    let id: String
    let name: String
    var medals: [UserMedal]
    var photoURL: String?

    static func ==(lhs: Participant, rhs: Participant) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
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
    @Published var participants: [Participant] = []
    @Published var participantProgresses: [ParticipantProgress] = []
    @Published var chatMessages: [ChallengeChatMessage] = []
    @Published var chatHasUnreadMessages: Bool = false
    @Published var premiumAttachments: [PremiumCalendarAttachment] = []
    @Published var isSavingPremiumContent: Bool = false

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
            async let allParticipants = try buildParticipants()
            async let progressesTask = try fetchParticipantProgresses()
            async let chatTask = try fetchChatMessages()

            let (posts, participants, progresses, chatMessages) = try await (postsTask, allParticipants, progressesTask, chatTask)

            await MainActor.run {
                self.updatePosts(posts)
                self.participants = participants
                self.participantProgresses = progresses
                self.updateChat(messages: chatMessages)
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

    func addAttachment(data: Data, title: String, kind: PremiumAttachmentKind, dayIndex: Int) async {
        do {
            let savedName = try persist(data: data, kind: kind)
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

    func detailButtonClicked(cell: CalendarDetailCell) {
        if !cell.posts.isEmpty {
            buildPagerInfo(cell: cell)
        }
    }

    func buildDetailcells(for selectedParticipant: Participant? = nil) -> [CalendarDetailCell] {
        let calendar = Calendar.current
        let participantMap = Dictionary(uniqueKeysWithValues: participants.map { ($0.id, $0) })

        return (0..<challenge.duration).compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day, to: challenge.startDate) else {
                return nil
            }

            let posts = allPosts.filter {
                Calendar.current.isDate($0.date, inSameDayAs: date)
                && (selectedParticipant != nil ? $0.authorUid == selectedParticipant?.id : true)
            }

            let jokerUsages: [CalendarDayJokerUsage] = participantProgresses.flatMap { progress -> [CalendarDayJokerUsage] in
                if let selectedParticipant, progress.id != selectedParticipant.id {
                    return []
                }

                guard let jokerProgress = progress.jokerProgress else { return [] }

                let usagesForDay = jokerProgress.confirmedUsages.filter {
                    calendar.isDate($0.date, inSameDayAs: date)
                }
                guard !usagesForDay.isEmpty else { return [] }

                let participant = participantMap[progress.id]

                return usagesForDay.map { usage in
                    CalendarDayJokerUsage(id: usage.id,
                                          participantId: progress.id,
                                          participantName: participant?.name ?? "Participant",
                                          participantPhotoURL: participant?.photoURL,
                                          declaredByAuthor: usage.declaredByAuthor,
                                          voterIds: usage.voters,
                                          voterNames: usage.voters.compactMap { participantMap[$0]?.name },
                                          postId: usage.postId)
                }
            }

            let isToday = calendar.isDateInToday(date)
            let attachments = attachments(for: day + 1)

            return CalendarDetailCell(date: date,
                                      posts: posts,
                                      jokers: jokerUsages.sorted(by: { $0.participantName.localizedCaseInsensitiveCompare($1.participantName) == .orderedAscending }),
                                      premiumAttachments: attachments,
                                      isToday: isToday)
        }
    }

    func jokerUsageCounts(for selectedParticipant: Participant? = nil) -> [Date: Int] {
        guard (challenge.jokerConfiguration?.jokersPerParticipant ?? 0) > 0 else { return [:] }

        let relevantProgresses: [ParticipantProgress]

        if let selectedParticipant {
            relevantProgresses = participantProgresses.filter { $0.id == selectedParticipant.id }
        } else {
            relevantProgresses = participantProgresses
        }

        guard !relevantProgresses.isEmpty else { return [:] }

        var counts: [Date: Int] = [:]
        counts.reserveCapacity(relevantProgresses.count * 2)

        let calendar = Calendar.current

        for progress in relevantProgresses {
            guard let jokerProgress = progress.jokerProgress else { continue }

            for usage in jokerProgress.confirmedUsages {
                let day = calendar.startOfDay(for: usage.date)
                counts[day, default: 0] += 1
            }
        }

        return counts
    }

    private func persist(data: Data, kind: PremiumAttachmentKind) throws -> String {
        let ext: String = kind == .pdf ? "pdf" : "dat"
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

    func getParticipant(for uid: String) -> Participant? {
        participants.first(where: { $0.id == uid })
    }

    var currentUserId: String? {
        challengeManager.currentUser?.id
    }

    var currentUserProgress: ParticipantProgress? {
        guard let currentUserId else { return nil }

        return participantProgresses.first(where: { $0.id == currentUserId })
    }

    var currentUserJokerStatus: (total: Int, remaining: Int)? {
        guard let progress = currentUserProgress else {
            guard let total = challenge.jokerConfiguration?.jokersPerParticipant, total > 0 else { return nil }
            return (total, total)
        }

        let total = progress.jokerProgress?.total ?? challenge.jokerConfiguration?.jokersPerParticipant ?? 0
        guard total > 0 else { return nil }
        let remaining = progress.jokerProgress?.remaining ?? total
        return (total, remaining)
    }

    func canUseJokerToday() -> Bool {
        guard let status = currentUserJokerStatus else { return false }
        guard status.remaining > 0 else { return false }

        guard let progress = currentUserProgress else { return true }

        let today = Calendar.current.startOfDay(for: Date())
        let hasValidatedToday = progress.validatedDays.contains { Calendar.current.isDate($0, inSameDayAs: today) }

        return !hasValidatedToday
    }

    func useJokerForToday() {
        guard canUseJokerToday() else { return }

        Task {
            do {
                try await challengeManager.declareJokerUsage(for: challenge,
                                                             on: Date(),
                                                             postId: nil)
                await MainActor.run {
                    self.fetchInfos()
                }
            } catch {
                print("❌ Failed to declare joker today: \(error)")
            }
        }
    }

    func markChatAsRead() {
        challengeManager.markChatAsRead(for: challenge.id)
        chatHasUnreadMessages = false
    }

    func sendChatMessage(content: String) async {
        do {
            try await challengeManager.sendChatMessage(content, challengeId: challenge.id)
            let messages = try await fetchChatMessages()

            await MainActor.run {
                self.updateChat(messages: messages)
                if !messages.isEmpty {
                    self.markChatAsRead()
                }
            }
        } catch {
            print("❌ Failed to send chat message: \(error)")
        }
    }

    func toggleReaction(_ reaction: String, for message: ChallengeChatMessage) async {
        guard let userId = challengeManager.currentUser?.id else { return }

        do {
            let latestMessages = try await fetchChatMessages()

            guard let targetMessage = latestMessages.first(where: { $0.id == message.id }) else {
                print("❌ Failed to resolve message for reaction toggle")
                return
            }

            let userHasReaction = targetMessage.reactions[reaction]?.contains(userId) ?? false

            if userHasReaction {
                try await challengeManager.removeChatReaction(reaction,
                                                              from: targetMessage,
                                                              challengeId: challenge.id,
                                                              userId: userId)
            } else {
                try await challengeManager.addChatReaction(reaction,
                                                           to: targetMessage,
                                                           challengeId: challenge.id,
                                                           userId: userId)
            }

            let refreshedMessages = try await fetchChatMessages()

            await MainActor.run {
                self.updateChat(messages: refreshedMessages)
            }
        } catch {
            print("❌ Failed to toggle reaction: \(error)")
        }
    }

    // MARK: - Private functions

    private func buildParticipants() async throws -> [Participant] {
        var allParticipants: [Participant] = []

        for participantUid in challenge.participantUids {
            guard let currentUser = challengeManager.currentUser,
                  let user = try await accountManager.fetchUser(uid: participantUid) else { continue }

            let participantName = currentUser.id == user.id ? "Moi" : user.name

            allParticipants.append(
                Participant(id: participantUid,
                            name: participantName,
                            medals: user.medals ?? [],
                            photoURL: user.photoURL)
            )
        }

        return allParticipants
    }

    private func fetchParticipantProgresses() async throws -> [ParticipantProgress] {
        var progresses = try await challengeManager.fetchParticipantsProgress(for: challenge.id)

        if let currentUserId = challengeManager.currentUser?.id,
           let index = progresses.firstIndex(where: { $0.id == currentUserId }),
           let updated = await challengeManager.autoDeclareMissedDayIfNeeded(for: challenge,
                                                                             progress: progresses[index]) {
            progresses[index] = updated
        }

        return progresses
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

    @MainActor
    private func updateChat(messages: [ChallengeChatMessage]) {
        self.chatMessages = messages

        self.chatHasUnreadMessages = challengeManager.hasUnreadMessages(for: challenge.id,
                                                                        latestMessageDate: messages.last?.createdAt)
    }
}
