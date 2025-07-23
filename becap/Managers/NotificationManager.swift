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

    func scheduleAllNotifications(for defi: Defi) {
        removeNotifications(for: defi)
        for config in defi.notificationConfig {
            for notifTime in config.times {
                // Calculate exact date for this dayIndex
                if let notifDate = Calendar.current.date(byAdding: .day, value: config.dayIndex, to: defi.startDate) {
                    let timeComps = Calendar.current.dateComponents([.hour, .minute], from: notifTime)
                    var dateComps = Calendar.current.dateComponents([.year, .month, .day], from: notifDate)
                    dateComps.hour = timeComps.hour
                    dateComps.minute = timeComps.minute

                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComps, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: notificationID(for: defi, dayIndex: config.dayIndex, time: notifTime),
                        content: makeContent(for: defi),
                        trigger: trigger
                    )
                    UNUserNotificationCenter.current().add(request)
                }
            }
        }
    }

    func removeNotifications(for defi: Defi) {
        let ids = defi.notificationConfig.flatMap { config in
            config.times.map { notificationID(for: defi, dayIndex: config.dayIndex, time: $0) }
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func notificationID(for defi: Defi, dayIndex: Int, time: Date) -> String {
        // Unique id: "defi-UUID-day-INDEX-time-<hour><minute>"
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        return "defi-\(defi.id.uuidString)-day-\(dayIndex)-h\(comps.hour ?? 0)m\(comps.minute ?? 0)"
    }

    private func makeContent(for defi: Defi) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Photo challenge: \(defi.name)"
        content.body = "It's time to post your picture for the challenge!"
        content.sound = .default
        return content
    }
}
