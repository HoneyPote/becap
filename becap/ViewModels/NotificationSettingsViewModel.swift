//
//  NotificationSettingsViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

class NotificationSettingsViewModel: ObservableObject {
    @Published var notificationConfig: [DefiNotificationDayConfig]
    let duration: Int

    init(config: [DefiNotificationDayConfig], duration: Int) {
        self.notificationConfig = config
        self.duration = duration
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

    // Appelle ce getter pour renvoyer la config éditée à DefiManager
    var updatedConfig: [DefiNotificationDayConfig] {
        notificationConfig
    }
}
