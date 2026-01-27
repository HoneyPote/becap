//
//  NewChallengeViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 28/07/2025.
//

import SwiftUI
import UserNotifications

class NewChallengeViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var duration: Int = defaultDuration {
        didSet { updateSuggestedJokersIfNeeded() }
    }
    @Published var category: ChallengeCategory = .autre
    @Published var notificationTimes: [NotificationTime] = []
    @Published var isLoading: Bool = false
    @Published var jokersNumber: Int = NewChallengeViewModel.suggestedJokerCount(for: defaultDuration) {
        didSet {
            if shouldIgnoreJokerUpdate {
                shouldIgnoreJokerUpdate = false
            } else if jokersNumber != oldValue {
                userCustomizedJokerCount = true
            }
        }
    }

    private var userCustomizedJokerCount = false
    private var shouldIgnoreJokerUpdate = false

    private let currentUser: User?
    private let accountManager: AccountManager
    private let challengeManager: ChallengeManager
    private let alertManager: GlobalAlertManager
    private let notificationManager: NotificationManager
    private static let defaultDuration = 30

    var trimmedNom: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isFormValid: Bool {
        !trimmedNom.isEmpty
    }

    init(userManager: UserManagerProtocol = UserManager.shared,
         accountManager: AccountManager = AccountManager(),
         challengeManager: ChallengeManager = ChallengeManager.shared,
         alertManager: GlobalAlertManager = GlobalAlertManager.shared,
         notificationManager: NotificationManager = NotificationManager.shared) {
        self.currentUser = userManager.currentUser
        self.accountManager = accountManager
        self.challengeManager = challengeManager
        self.alertManager = alertManager
        self.notificationManager = notificationManager
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
                guard let newChallenge = try await challengeManager.createChallenge(newChallenge)
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
        let code = String((0..<6).compactMap { _ in "0123456789".randomElement() })

        return Challenge(title: name,
                         duration: duration,
                         startDate: Date(),
                         creatorUID: userId,
                         adminUids: [userId],
                         participantUids: [userId],
                         category: category,
                         defaultNotificationsConfig: notificationTimes.map { $0.minutes },
                         code: code,
                         jokerConfiguration: jokersNumber)
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

    private func updateSuggestedJokersIfNeeded() {
        guard !userCustomizedJokerCount else { return }

        shouldIgnoreJokerUpdate = true
        jokersNumber = NewChallengeViewModel.suggestedJokerCount(for: duration)
    }

    private static func suggestedJokerCount(for duration: Int) -> Int {
        switch duration {
        case ..<7:
            return 0
        case 7:
            return 1
        case 8...14:
            return 2
        case 15...21:
            return 3
        case 22...35:
            return 4
        default:
            return max(4, Int(round(Double(duration) / 7.0)))
        }
    }
}
