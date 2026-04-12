//
//  CreateBecapChallengeViewModel.swift
//  becap
//
//  Created by Victor Derveaux on 06/02/2026.
//

import SwiftUI

class CreateBecapChallengeViewModel: ObservableObject {
    @Published var duration: Int = defaultDuration
    @Published var notificationTimes: [NotificationTime] = []
    @Published var isLoading: Bool = false
    @Published var becapConfiguration: BecapChallengeConfiguration

    private var userCustomizedJokerCount = false
    private var shouldIgnoreJokerUpdate = false

    private let currentUser: User?
    private let accountManager: AccountManager
    private let challengeManager: ChallengeManager
    private let alertManager: GlobalAlertManager
    private let notificationManager: NotificationManager
    private static let defaultDuration = 30

    var challengeName: String {
        switch type {
        case .plank:
            "Gainage"
        case .reading:
            "Lecture"
        case .food:
            "Nourriture"
        case .drawing:
            "Dessin"
        }
    }

    var challengeCategory: ChallengeCategory {
        switch type {
        case .plank: .sport
        case .reading: .reading
        case .food: .food
        case .drawing: .drawing
        }
    }

    let type: BecapChallengeType

    init(type: BecapChallengeType,
         userManager: UserManagerProtocol = UserManager.shared,
         accountManager: AccountManager = AccountManager(),
         challengeManager: ChallengeManager = ChallengeManager.shared,
         alertManager: GlobalAlertManager = GlobalAlertManager.shared,
         notificationManager: NotificationManager = NotificationManager.shared) {
        self.type = type
        self.becapConfiguration = type.defaultConfiguration

        self.currentUser = userManager.currentUser
        self.accountManager = accountManager
        self.challengeManager = challengeManager
        self.alertManager = alertManager
        self.notificationManager = notificationManager
    }

    func createBecapChallenge(completion: @escaping (Bool) -> Void) {
        isLoading = true

        guard let currentUser, let currentUserId = currentUser.id else {
            isLoading = false
            completion(false)
            return
        }

        let newChallenge = buildNewChallenge(userId: currentUserId)

        Task {
            do {
                guard let newChallenge = try await challengeManager.createChallenge(newChallenge)
                else { return }

                let newBecapData = buildNewBecapData(challengeId: newChallenge.id)

                guard let newBecapChallengeData = try await challengeManager.createBecapChallengeData(newBecapData)
                else { return }

                try await challengeManager.createNewParticipantProgress(userId: currentUserId,
                                                                        challenge: newChallenge)

                await challengeManager.assignCreationMedalsToUser(currentUserId)

                try await refreshUserMedals(userId: currentUserId)

                await MainActor.run {
                    self.notificationManager.scheduleDailyNotifications(for: newChallenge, config: newChallenge.defaultNotificationsConfig)
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

    func addNotificationTime() {
        guard notificationTimes.count < 3 else { return }

        notificationTimes.append(NotificationTime(id: UUID(), minutes: Date().convertToMinutes))
    }

    func updateNotificationTime(index: Int, newDate: Date) {
        guard notificationTimes.indices.contains(index) else { return }

        notificationTimes[index].minutes = newDate.convertToMinutes
        sortNotificationTimes()
    }

    func removeNotificationTime(at index: Int) {
        guard notificationTimes.indices.contains(index) else { return }

        notificationTimes.remove(at: index)
    }

    // MARK: - Private functions

    private func buildNewChallenge(userId: String) -> Challenge {
        // TODO: Make sure created code is not already taken by another challenge
        let code = String((0..<6).compactMap { _ in "0123456789".randomElement() })

        return Challenge(title: challengeName,
                         duration: duration,
                         startDate: Date(),
                         creatorUID: userId,
                         adminUids: [userId],
                         participantUids: [userId],
                         category: challengeCategory,
                         defaultNotificationsConfig: notificationTimes.map { $0.minutes },
                         code: code,
                         jokerConfiguration: 0)
    }

    private func buildNewBecapData(challengeId: String) -> BecapChallengeData {
        BecapChallengeData(challengeId: challengeId,
                           type: type,
                           configuration: becapConfiguration)
    }

    private func sortNotificationTimes() {
        let sortedTimes = Dictionary(grouping: notificationTimes, by: \.minutes)
            .compactMap { $0.value.first }
            .sorted { $0.minutes < $1.minutes }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            notificationTimes = sortedTimes
        }
    }

    private func refreshUserMedals(userId: String) async throws {
        Task {
            guard let newUser = try await accountManager.updateCurrentUser(with: userId) else { return }

            await MainActor.run {
                // 🎖️ Affiche les médailles gagnées aujourd'hui
                let today = Calendar.current.startOfDay(for: Date())
                let medalsToday = newUser.medals.filter {
                    Calendar.current.isDate($0.achievedDate, inSameDayAs: today)
                }
                alertManager.show(medals: medalsToday)
            }
        }
    }
}
