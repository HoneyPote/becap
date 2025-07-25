//
//  NotificationSettingsViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

class NotificationSettingsViewModel: ObservableObject {
    @Published var notificationConfig: [ChallengeNotification]

    private let challengeManager: ChallengeManager

    let currentChallenge: Challenge
    let duration: Int

    // Getter pour renvoyer la config éditée à ChallengeManager ou ChallengeService
    var updatedConfig: [ChallengeNotification] {
        notificationConfig
    }

    init(challengeManager: ChallengeManager = ChallengeManager.shared, currentChallenge: Challenge) {
        self.challengeManager = challengeManager
        self.currentChallenge = currentChallenge
        self.notificationConfig = currentChallenge.notificationsConfig ?? []
        self.duration = currentChallenge.duration
    }

    func addTime(for day: Int, date: Date) {
        guard day < notificationConfig.count, notificationConfig[day].times.count < 3 else { return }
        notificationConfig[day].times.append(date)
    }

    func removeTime(for day: Int, at index: Int) {
        guard day < notificationConfig.count, index < notificationConfig[day].times.count else { return }
        notificationConfig[day].times.remove(at: index)
    }

    func resetAll() {
        for i in 0..<notificationConfig.count {
            notificationConfig[i].times = []
        }
    }

    func duplicateDay(_ day: Int) {
        guard day < notificationConfig.count else { return }
        let times = notificationConfig[day].times
        for i in 0..<notificationConfig.count {
            notificationConfig[i].times = times
        }
    }

    func updateNotificationConfig() {
        challengeManager.updateNotifications(for: currentChallenge, config: updatedConfig)
    }
}
