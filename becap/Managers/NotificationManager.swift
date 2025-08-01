//
//  NotificationManager.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

// ChallengeApp/Managers/NotificationManager.swift

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    func scheduleAllNotifications(for challenge: Challenge) {
        removeNotifications(for: challenge)
        guard let notificationsConfig = challenge.notificationsConfig else { return }

        for config in notificationsConfig {
            for notifTime in config.times {
                if let notifDate = Calendar.current.date(byAdding: .day, value: config.dayIndex, to: challenge.startDate) {
                    let timeComps = Calendar.current.dateComponents([.hour, .minute], from: notifTime)
                    var dateComps = Calendar.current.dateComponents([.year, .month, .day], from: notifDate)
                    dateComps.hour = timeComps.hour
                    dateComps.minute = timeComps.minute

                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComps, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: notificationID(for: challenge, dayIndex: config.dayIndex, time: notifTime),
                        content: makeContent(for: challenge),
                        trigger: trigger
                    )
                    UNUserNotificationCenter.current().add(request)
                }
            }
        }
    }

    func removeNotifications(for challenge: Challenge) {
        guard let notificationsConfig = challenge.notificationsConfig else { return }
        let ids = notificationsConfig.flatMap { config in
            config.times.map { notificationID(for: challenge, dayIndex: config.dayIndex, time: $0) }
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // Privates

    private func notificationID(for challenge: Challenge, dayIndex: Int, time: Date) -> String {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let idStr = challenge.id ?? "noid"
        return "challenge-\(idStr)-day-\(dayIndex)-h\(comps.hour ?? 0)m\(comps.minute ?? 0)"
    }

    private func makeContent(for challenge: Challenge) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Photo challenge: \(challenge.title)"
        content.body = "It's time to post your picture for the challenge!"
        content.sound = .default
        return content
    }
}
