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
        var timeToAdd = date

        // Si la date est aujourd'hui et passée, décale de 1 jour ou 1 min
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayDate = calendar.date(byAdding: .day, value: day, to: today)!

        let combinedDate = calendar.date(bySettingHour: calendar.component(.hour, from: timeToAdd),
                                         minute: calendar.component(.minute, from: timeToAdd),
                                         second: 0,
                                         of: dayDate)!

        if combinedDate < Date() {
            // Déplace dans le futur
            timeToAdd = calendar.date(byAdding: .minute, value: 1, to: Date())!
        }

        notificationConfig[day].times.append(timeToAdd)
    }
    func updateTime(for day: Int, oldTime: Date, newTime: Date) {
        guard notificationConfig.indices.contains(day) else { return }
        if let index = notificationConfig[day].times.firstIndex(of: oldTime) {
            notificationConfig[day].times[index] = newTime
        }
    }

    func removeTime(for day: Int, time: Date) {
        guard notificationConfig.indices.contains(day) else { return }
        notificationConfig[day].times.removeAll { $0 == time }
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
