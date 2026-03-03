//
//  NotificationManager.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import Foundation
import UserNotifications

struct NotificationTime: Identifiable, Equatable {
    let id: UUID
    var minutes: Int

    var fullDate: Date {
        minutes.convertToDate
    }
}

final class NotificationManager {
    static let shared = NotificationManager()

    private let notificationService: NotificationService

    init(notificationService: NotificationService = NotificationService()) {
        self.notificationService = notificationService
    }

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    completion?(granted)
                }
            }
    }

    func scheduleDailyNotifications(for challenge: any ChallengeRepresentable, config: [Int]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        for minutes in config {
            var dateComponents = DateComponents()
            dateComponents.hour = minutes / 60
            dateComponents.minute = minutes % 60

            let identifier = notificationID(for: challenge, time: minutes.convertToDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: identifier,
                                                content: makeContent(for: challenge),
                                                trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("❌ Erreur notif : \(error)")
                }
            }
        }

        debugLogScheduledNotifications()
    }

    func setOneSignalPushId(to userId: String) {
        notificationService.loginOneSignalUser(with: userId)
        notificationService.setOneSignalPushId(to: userId)
    }

    // Privates

    private func notificationID(for challenge: any ChallengeRepresentable, time: Date) -> String {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)

        return "challenge-\(challenge.id)-h\(comps.hour ?? 0)m\(comps.minute ?? 0)"
    }

    private func makeContent(for challenge: any ChallengeRepresentable) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = challenge.title
        content.body = "C’est l’heure de poster pour ton défi 💪"
        content.sound = .default
        return content
    }

    private func debugLogScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 Notifications planifiées :")
            for r in requests {
                if let trigger = r.trigger as? UNCalendarNotificationTrigger {
                    print("🕒 ID: \(r.identifier), next: \(String(describing: trigger.nextTriggerDate()))")
                }
            }
        }
    }
}
