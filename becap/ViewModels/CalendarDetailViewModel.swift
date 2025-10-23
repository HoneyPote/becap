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

struct CalendarDetailCell: Hashable,Identifiable {
    var date: Date
    var photos: [ChallengePhoto]
    var isToday: Bool

    var id: Date { date }
}

class CalendarDetailViewModel: ObservableObject {
    @Published var allPhotos: [ChallengePhoto] = []
    @Published var detailCells: [CalendarDetailCell]?
    @Published var doneLoadingPhotos: Bool = false
    @Published var selectedPagerInfo: PagerInfo?
    @Published var participants: [Participant] = []
    @Published var participantProgresses: [ParticipantProgress] = []
    @Published var chatMessages: [ChallengeChatMessage] = []
    @Published var chatHasUnreadMessages: Bool = false

    private let accountManager: AccountManager
    private let challengeManager: ChallengeManager

    let challenge: Challenge

    init(accountManager: AccountManager = AccountManager(),
         challengeManager: ChallengeManager = ChallengeManager.shared,
         challenge: Challenge) {
        self.accountManager = accountManager
        self.challengeManager = challengeManager
        self.challenge = challenge
    }

    func fetchInfos() {
        self.doneLoadingPhotos = false

        Task {
            async let photosTask = try fetchPhotos()
            async let allParticipants = try buildParticipants()
            async let progressesTask = try fetchParticipantProgresses()
            async let chatTask = try fetchChatMessages()

            let (photos, participants, progresses, chatMessages) = try await (photosTask, allParticipants, progressesTask, chatTask)

            await MainActor.run {
                self.updatePhotos(photos)
                self.participants = participants
                self.participantProgresses = progresses
                self.updateChat(messages: chatMessages)
                self.doneLoadingPhotos = true
            }
        }
    }

    func canDeletePhoto(photos: [ChallengePhoto]) -> Bool {
        guard let currentUser = challengeManager.currentUser, let currentUserId = currentUser.id else { return false }

        return photos.first?.authorUid == currentUserId
    }

    func detailButtonClicked(cell: CalendarDetailCell) {
        if !cell.photos.isEmpty {
            buildPagerInfo(cell: cell)
        }
    }

    func buildDetailcells(for selectedParticipant: Participant? = nil) -> [CalendarDetailCell] {
        return (0..<challenge.duration).compactMap { day in
            guard let date = Calendar.current.date(byAdding: .day, value: day, to: challenge.startDate) else {
                return nil
            }

            let photos = allPhotos.filter {
                Calendar.current.isDate($0.date, inSameDayAs: date) && (selectedParticipant != nil ? $0.authorUid == selectedParticipant?.id : true)
            }
            let isToday = Calendar.current.isDateInToday(date)

            return CalendarDetailCell(date: date, photos: photos, isToday: isToday)
        }
    }

    func deletePhoto(_ photoId: String) {
        self.allPhotos.removeAll(where: { $0.id == photoId })
    }

    func getParticipant(for uid: String) -> Participant? {
        participants.first(where: { $0.id == uid })
    }

    var currentUserId: String? {
        challengeManager.currentUser?.id
    }

    @MainActor
    func markChatAsRead() {
        guard let challengeId = challenge.id else { return }

        challengeManager.markChatAsRead(for: challengeId)
        chatHasUnreadMessages = false
    }

    func sendChatMessage(content: String) async {
        guard let challengeId = challenge.id else { return }

        do {
            try await challengeManager.sendChatMessage(content, challengeId: challengeId)
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
        guard let challengeId = challenge.id else { return [] }

        return try await challengeManager.fetchParticipantsProgress(for: challengeId)
    }

    private func fetchChatMessages() async throws -> [ChallengeChatMessage] {
        guard let challengeId = challenge.id else { return [] }

        return try await challengeManager.fetchChatMessages(for: challengeId)
    }

    private func buildPagerInfo(cell: CalendarDetailCell) {
        selectedPagerInfo = PagerInfo(photos: cell.photos, index: 0, date: cell.date)
    }

    private func fetchPhotos() async throws -> [ChallengePhoto] {
        guard let challengeId = challenge.id else { return [] }

        return try await challengeManager.loadPhotos(from: challengeId)
    }

    private func updatePhotos(_ photos: [ChallengePhoto]) {
        self.allPhotos = photos
    }

    @MainActor
    private func updateChat(messages: [ChallengeChatMessage]) {
        self.chatMessages = messages

        guard let challengeId = challenge.id else {
            self.chatHasUnreadMessages = false
            return
        }

        self.chatHasUnreadMessages = challengeManager.hasUnreadMessages(
            for: challengeId,
            latestMessageDate: messages.last?.createdAt
        )
    }
}
