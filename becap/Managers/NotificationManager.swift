//
//  NotificationManager.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private let notificationService: NotificationService

    init(notificationService: NotificationService = NotificationService()) {
        self.notificationService = notificationService
        super.init()
        UNUserNotificationCenter.current().delegate = self
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
        let idStr = challenge.id ?? "noid"
        return "challenge-\(idStr)-day-\(dayIndex)-h\(comps.hour ?? 0)m\(comps.minute ?? 0)"
    }

    private func makeContent(for challenge: Challenge) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Photo challenge: \(challenge.title)"
        content.body = "It's time to post your picture for the challenge!"
        content.sound = .default
        if let challengeId = challenge.id {
            content.userInfo = [
                "type": AppNotificationKind.reminder.rawValue,
                "challengeId": challengeId,
                "challengeTitle": challenge.title
            ]
        }
        return content
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .banner, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let route = route(from: response.notification.request.content.userInfo) {
            NotificationCenter.default.post(name: .didReceiveNotificationRoute, object: route)
        }
        completionHandler()
    }

    private func route(from userInfo: [AnyHashable: Any]) -> NotificationRoute? {
        guard let typeString = userInfo["type"] as? String,
              let kind = AppNotificationKind(rawValue: typeString) else { return nil }

        switch kind {
        case .photoPosted, .like:
            guard let challengeId = userInfo["challengeId"] as? String,
                  let photoId = userInfo["photoId"] as? String else { return nil }
            let commentId = userInfo["commentId"] as? String
            return .photo(challengeId: challengeId, photoId: photoId, commentId: commentId)
        case .comment:
            guard let challengeId = userInfo["challengeId"] as? String,
                  let photoId = userInfo["photoId"] as? String else { return nil }
            let commentId = userInfo["commentId"] as? String
            return .photo(challengeId: challengeId, photoId: photoId, commentId: commentId)
        case .reminder:
            guard let challengeId = userInfo["challengeId"] as? String else { return nil }
            return .challenge(challengeId: challengeId)
        }
    }
}
