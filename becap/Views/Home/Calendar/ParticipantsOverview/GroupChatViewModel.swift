//
//  GroupChatViewModel.swift
//  becap
//
//  Created by Victor Derveaux on 02/12/2025.
//

import Foundation

class GroupChatViewModel: ObservableObject {
    @Published var allMessages: [ChallengeChatMessage] = []

    let challenge: any ChallengeRepresentable

    private let userManager: UserManager
    private let challengeManager: ChallengeManager
    private let challengeService: ChallengeService

    init(userManager: UserManager = UserManager.shared,
         challengeManager: ChallengeManager = ChallengeManager.shared,
         challengeService: ChallengeService = ChallengeService.shared,
         challenge: any ChallengeRepresentable) {
        self.userManager = userManager
        self.challengeManager = challengeManager
        self.challengeService = challengeService
        self.challenge = challenge

        listenToChat()
    }

    func onAppear() {
        Task {
            do {
                let messages = try await fetchChatMessages()

                await MainActor.run {
                    self.allMessages = messages
                    self.markChatAsRead()
                }
            } catch {
                print("❌ Failed to fetch chat messages: \(error)")
            }
        }
    }

    func isFromCurrentUser(_ message: ChallengeChatMessage) -> Bool {
        guard let currentUserId = userManager.currentUser?.id else { return false }
        return message.senderId == currentUserId
    }

    func markChatAsRead() {
        challengeManager.markChatAsRead(for: challenge.id)
//        chatHasUnreadMessages = false
    }

    func sendChatMessage(content: String) {
        Task {
            do {
                try await challengeManager.sendChatMessage(content, challengeId: challenge.id)
            } catch {
                print("❌ Failed to send chat message: \(error)")
            }
        }
    }

    func toggleReaction(_ reaction: String, for message: ChallengeChatMessage) {
        guard let userId = challengeManager.currentUser?.id else { return }

        Task {
            do {
                if userHasReacted(to: message, with: reaction) {
                    try await challengeManager.removeChatReaction(reaction,
                                                                  from: message,
                                                                  challengeId: challenge.id,
                                                                  userId: userId)
                } else {
                    try await challengeManager.addChatReaction(reaction,
                                                               to: message,
                                                               challengeId: challenge.id,
                                                               userId: userId)
                }
            } catch {
                print("❌ Failed to toggle reaction: \(error)")
            }
        }
    }

    func reactionBadgeIsHighlighted(entryUsers: [String]) -> Bool {
        guard let currentUserId = userManager.currentUser?.id else { return false }
        return entryUsers.contains(where: { $0 == currentUserId } )
    }

    func hasReacted(to message: ChallengeChatMessage, with reaction: String) -> String {
        return "\(reaction) " + (userHasReacted(to: message, with: reaction) ? "Retirer" : "Ajouter")
    }

    private func listenToChat() {
        challengeService.listenToGroupChat(challengeId: challenge.id) { [weak self] updated in
            DispatchQueue.main.async {
                self?.allMessages = updated
            }
        }
    }

    private func userHasReacted(to message: ChallengeChatMessage, with reaction: String) -> Bool {
        guard let currentUserId = userManager.currentUser?.id else { return false }
        return message.reactions[reaction]?.contains(currentUserId) ?? false
    }

    private func fetchChatMessages() async throws -> [ChallengeChatMessage] {
        return try await challengeManager.fetchChatMessages(for: challenge.id)
    }

    private func updateChat(messages: [ChallengeChatMessage]) {
        self.allMessages = messages

//        self.chatHasUnreadMessages = challengeManager.checkForUnreadMessages(for: challenge.id,
//                                                                         latestMessageDate: messages.last?.createdAt)
    }
}
