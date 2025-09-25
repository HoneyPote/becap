//
//  NewChallengeViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 28/07/2025.
//

import SwiftUI
import UserNotifications

class NewChallengeViewModel: ObservableObject {
    @Published var nom: String = ""
    @Published var duree: Int = 30
    @Published var heureNotification: Date = Date()
    @Published var isLoading: Bool = false

    private let currentUser: User?

    private let accountManager: AccountManager
    private let challengeManager: ChallengeManager
    private let alertManager: GlobalAlertManager

    var isFormValid: Bool {
        !nom.isEmpty
    }

    init(userManager: UserManagerProtocol = UserManager.shared,
         accountManager: AccountManager = AccountManager(),
         challengeManager: ChallengeManager = ChallengeManager.shared,
         alertManager: GlobalAlertManager = GlobalAlertManager.shared) {
        self.currentUser = userManager.currentUser
        self.accountManager = accountManager
        self.challengeManager = challengeManager
        self.alertManager = alertManager
    }

    func createChallenge(completion: @escaping (Bool) -> Void) {
        isLoading = true

        guard let currentUser, let currentUserId = currentUser.id else {
            isLoading = false
            completion(false)
            return
        }

        let newChallenge = buildNewChallenge(userId: currentUserId)

        Task {
            do {
                guard let newChallenge = try await challengeManager.createChallenge(newChallenge),
                      let newChallengeId = newChallenge.id else { return }

                try await challengeManager.createNewParticipantProgress(userId: currentUserId,
                                                                        challengeId: newChallengeId)

                await challengeManager.assignCreationMedalsToUser(currentUserId)

                try await refreshUserMedals(userId: currentUserId)

                await MainActor.run {
                    //self.challengeManager.participants[newChallengeId] = [userProgress] // TODO: Utile ?
                    self.isLoading = false
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    completion(false)
                }
            }
        }
    }

    // MARK: - Private functions

    private func refreshUserMedals(userId: String) async throws {
        Task {
            guard let newUser = try await accountManager.updateCurrentUser(with: userId) else { return }

            await MainActor.run {
                // 🎖️ Affiche les médailles gagnées aujourd'hui
                let today = Calendar.current.startOfDay(for: Date())
                for medal in newUser.medals ?? [] {
                    if Calendar.current.isDate(medal.achievedDate, inSameDayAs: today) {
                        alertManager.show(medal: medal, challengeId: medal.challengeId)
                    }
                }
            }
        }
    }

    private func buildNewChallenge(userId: String) -> Challenge {
        let config: [ChallengeNotification] = (0..<duree).map {
            ChallengeNotification(dayIndex: $0, times: [heureNotification])
        }
        let code = String((0..<6).compactMap { _ in "0123456789".randomElement() })

        return Challenge(id: nil,
                         title: nom,
                         duration: duree,
                         startDate: Date(),
                         creatorUID: userId,
                         participantUids: [userId],
                         notificationsConfig: config,
                         code: code)
    }
}
