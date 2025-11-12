//
//  NotificationManager.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private let notificationService: NotificationService

    init(notificationService: NotificationService = NotificationService()) {
        self.notificationService = notificationService
    }

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

        var upcomingNotifs: [(date: Date, id: String)] = []

        for config in notificationsConfig {
            for notifTime in config.times {
                if let notifDate = Calendar.current.date(byAdding: .day, value: config.dayIndex, to: challenge.startDate) {
                    let timeComps = Calendar.current.dateComponents([.hour, .minute], from: notifTime)
                    var dateComps = Calendar.current.dateComponents([.year, .month, .day], from: notifDate)
                    dateComps.hour = timeComps.hour
                    dateComps.minute = timeComps.minute

                    if let finalDate = Calendar.current.date(from: dateComps), finalDate > Date() {
                        let id = notificationID(for: challenge, dayIndex: config.dayIndex, time: notifTime)
                        upcomingNotifs.append((date: finalDate, id: id))
                    } else {
                        print("⚠️ Notification ignorée (date dans le passé): \(String(describing: Calendar.current.date(from: dateComps)))")
                    }
                }
            }
        }

        // Tri par date + limitation aux 20 plus proches
        let limitedNotifs = upcomingNotifs.sorted(by: { $0.date < $1.date }).prefix(63)

        for notif in limitedNotifs {
            let dateComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notif.date)

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComps, repeats: false)
            let request = UNNotificationRequest(
                identifier: notif.id,
                content: makeContent(for: challenge),
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Erreur notif : \(error)")
                }
            }
        }

        // Log des notifs planifiées
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 Notifications planifiées :")
            for r in requests {
                if let trigger = r.trigger as? UNCalendarNotificationTrigger {
                    print("🕒 ID: \(r.identifier), nextTriggerDate: \(String(describing: trigger.nextTriggerDate()))")
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

    func setOneSignalPushId(to userId: String) {
        notificationService.loginOneSignalUser(with: userId)
        notificationService.setOneSignalPushId(to: userId)
    }

    // Privates

    private func notificationID(for challenge: Challenge, dayIndex: Int, time: Date) -> String {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let idStr = challenge.id
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
