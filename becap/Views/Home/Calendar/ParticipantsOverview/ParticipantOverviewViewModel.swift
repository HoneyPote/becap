//
//  ParticipantCardViewModel.swift
//  becap
//
//  Created by Victor Derveaux on 27/11/2025.
//

import Foundation

class ParticipantOverviewViewModel: ObservableObject {
    @Published var showingAlert = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""

    let challenge: Challenge
    let participants: [ParticipantUIModel]
    let hasUnreadMessages: Bool

    private let challengeManager: ChallengeManager
    private let challengeService: ChallengeService
    private let userManager: UserManager
    private let currentUser: User?

    var currentUserIsAdmin: Bool {
        guard let currentUser else { return false }
        return challenge.adminUids.contains(where: { $0 == currentUser.id })
    }

    func participantTitles(participant: ParticipantUIModel) -> String? {
        var titles: String = ""

        if participant.userId == challenge.creatorUID {
            titles.append("Créateur")

            if participant.isAdmin {
                titles.append(", administrateur")
            }
        } else if participant.isAdmin {
            titles.append("Administrateur")
        }

        return titles.isEmpty ? nil : titles
    }

    init(challengeManager: ChallengeManager = ChallengeManager.shared,
         challengeService: ChallengeService = ChallengeService.shared,
         userManager: UserManager = UserManager.shared,
         challenge: Challenge,
         participants: [ParticipantUIModel]) {
        self.challengeManager = challengeManager
        self.challengeService = challengeService
        self.userManager = userManager
        self.challenge = challenge
        self.participants = participants
        self.hasUnreadMessages = challengeManager.getHasUnreadMessages(for: challenge.id)
        self.currentUser = userManager.currentUser
    }

    func userIsAdmin(_ userId: String) -> Bool {
        challenge.adminUids.contains(where: { $0 == userId })
    }

    func showPromoteToAdminButton(for participant: ParticipantUIModel) -> Bool {
        currentUserIsAdmin
        && !isCurrentUser(for: participant.userId)
        && !participant.progress.isBlocked
        && !userIsAdmin(participant.userId)
    }

    func showQuitButton(for participant: ParticipantUIModel) -> Bool {
        isCurrentUser(for: participant.userId) && !participant.progress.isBlocked
    }

    func showBlockParticipantButton(for participant: ParticipantUIModel) -> Bool {
        currentUserIsAdmin && !isCurrentUser(for: participant.userId) && !participant.progress.isBlocked
    }

    func isCurrentUser(for userId: String) -> Bool {
        userId == currentUser?.id
    }

    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }

    func buildParticipantStats(for participant: ParticipantUIModel) -> ParticipantOverviewStats {
        let likes = participant.posts.reduce(0) { partialResult, post in
            partialResult + (post.likes?.count ?? 0)
        }
        let progress = participant.progress
        let jokerProgress = progress.jokerProgress

        return ParticipantOverviewStats(postsCount: participant.posts.count,
                                        likesCount: likes,
                                        streak: progress.currentStreak,
                                        validatedDays: progress.validatedDays.count,
                                        totalJokers: jokerProgress.total,
                                        remainingJokers: jokerProgress.remaining)
    }

    func promoteToAdmin(userId: String) {
        guard currentUserIsAdmin else { return }

        Task {
            do {
                try await challengeService.addAdminUid(challengeId: challenge.id, uid: userId)
            }
        }
    }

    func blockParticipant(userId: String) {
        guard currentUserIsAdmin else { return }

        Task {
            do {
                try await challengeManager.removeParticipant(challenge.id, userId: userId)
            }
        }
    }

    func quitChallenge(completion: @escaping (Bool) -> Void) {
        guard let currentUserId = currentUser?.id else { return }

        Task {
            do {
                try await challengeManager.removeParticipant(challenge.id, userId: currentUserId)

                await MainActor.run {
                    completion(true)
                }
            } catch ChallengeManagerError.userSoloAdmin {
                await MainActor.run {
                    self.presentAlert(title: "Impossible de quitter le défi", message: "Vous semblez être le seul administrateur dans ce défi. Veuillez promouvoir un autre membre pour pouvoir quitter le défi.")
                    completion(false)
                }
            }
        }
    }
}
