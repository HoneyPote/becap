//
//  NotificationService.swift
//  becap
//
//  Created by Victor Derveaux on 18/08/2025.
//

import Foundation
import FirebaseFirestore
import OneSignalFramework

class NotificationService {
    static let shared = NotificationService()

    private let db = Firestore.firestore()
    private let notificationCollection = "notifications"

    var currentOneSignalPushId: String? {
        OneSignal.User.pushSubscription.id
    }

    func setupOneSignal(didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) {
        // Enable verbose logging for debugging (remove in production)
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        // Initialize with your OneSignal App ID
        OneSignal.initialize("58d11a0f-cf16-4555-b258-c94d6afa0af3", withLaunchOptions: launchOptions)
        // Use this method to prompt for push notifications.
        // We recommend removing this method after testing and instead use In-App Messages to prompt for notification permission.
        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
        }, fallbackToSettings: false)

        OneSignal.Notifications.addClickListener { [weak self] result in
            guard let data = result.notification.additionalData,
                  let route = self?.notificationRoute(from: data) else { return }

            NotificationCenter.default.post(name: .didReceiveNotificationRoute, object: route)
        }
    }

    func loginOneSignalUser(with userId: String) {
        OneSignal.login(userId)
    }

    func logoutOneSignalUser() {
        OneSignal.logout()
    }

    func setOneSignalPushId(to userId: String) {
        guard let oneSignalPushId = self.currentOneSignalPushId else { return }

        let ref = db.collection("users").document(userId)

        ref.setData(["onesignalPlayerId": oneSignalPushId], merge: true)
    }

    func sendPhotoNotification(to participantIds: [String],
                               author: User,
                               challenge: Challenge,
                               photo: ChallengePhoto) async {
        guard let authorId = author.id,
              let challengeId = challenge.id,
              let photoId = photo.id else { return }

        let recipients = participantIds.filter { $0 != authorId }
        let pushRecipients = (try? await fetchOneSignalPushIds(userIds: recipients)) ?? []

        let title = "Nouveau post dans \"\(challenge.title)\""
        let message = "\(author.name) a posté une nouvelle photo !"

        if !pushRecipients.isEmpty {
            var payload: [String: Any] = [
                "app_id": "58d11a0f-cf16-4555-b258-c94d6afa0af3",
                "include_player_ids": pushRecipients,
                "headings": ["en": title, "fr": title],
                "contents": ["en": message, "fr": message],
                "ios_sound": "default"
            ]

            payload["data"] = notificationData(kind: .photoPosted,
                                                 challengeId: challengeId,
                                                 challengeTitle: challenge.title,
                                                 photoId: photoId,
                                                 commentId: nil,
                                                 actorName: author.name)

            sendUrlRequestNotification(payload: payload)
        }

        await persistNotifications(for: recipients,
                                   kind: .photoPosted,
                                   title: title,
                                   message: message,
                                   challengeId: challengeId,
                                   challengeTitle: challenge.title,
                                   photoId: photoId,
                                   commentId: nil,
                                   actorName: author.name)
    }

    func sendLikeNotification(to authorUid: String,
                              from user: User,
                              challenge: Challenge,
                              photo: ChallengePhoto) async {
        guard let challengeId = challenge.id,
              let photoId = photo.id else { return }

        let title = "Nouvelle mention J’aime !"
        let message = "\(user.name) a liké ta photo dans \"\(challenge.title)\""

        if let pushId = try? await fetchOneSignalPushIds(userIds: [authorUid]).first {
            var payload: [String: Any] = [
                "app_id": "58d11a0f-cf16-4555-b258-c94d6afa0af3",
                "include_player_ids": [pushId],
                "headings": ["en": title, "fr": title],
                "contents": ["en": message, "fr": message],
                "ios_sound": "default"
            ]

            payload["data"] = notificationData(kind: .like,
                                                 challengeId: challengeId,
                                                 challengeTitle: challenge.title,
                                                 photoId: photoId,
                                                 commentId: nil,
                                                 actorName: user.name)

            sendUrlRequestNotification(payload: payload)
        }

        await persistNotifications(for: [authorUid],
                                   kind: .like,
                                   title: title,
                                   message: message,
                                   challengeId: challengeId,
                                   challengeTitle: challenge.title,
                                   photoId: photoId,
                                   commentId: nil,
                                   actorName: user.name)
    }

    func sendCommentNotification(to authorUid: String,
                                 from user: User,
                                 challenge: Challenge,
                                 photo: ChallengePhoto,
                                 comment: PhotoCommentModel) async {
        guard let challengeId = challenge.id,
              let photoId = photo.id,
              let commentId = comment.id else { return }

        let title = "Nouveau commentaire 💬"
        let truncatedText = truncatedComment(comment.content)
        let message = "\(user.name) a commenté ta photo dans \"\(challenge.title)\" : \"\(truncatedText)\""

        if let pushId = try? await fetchOneSignalPushIds(userIds: [authorUid]).first {
            var payload: [String: Any] = [
                "app_id": "58d11a0f-cf16-4555-b258-c94d6afa0af3",
                "include_player_ids": [pushId],
                "headings": ["en": title, "fr": title],
                "contents": ["en": message, "fr": message],
                "ios_sound": "default"
            ]

            payload["data"] = notificationData(kind: .comment,
                                                 challengeId: challengeId,
                                                 challengeTitle: challenge.title,
                                                 photoId: photoId,
                                                 commentId: commentId,
                                                 actorName: user.name)

            sendUrlRequestNotification(payload: payload)
        }

        await persistNotifications(for: [authorUid],
                                   kind: .comment,
                                   title: title,
                                   message: message,
                                   challengeId: challengeId,
                                   challengeTitle: challenge.title,
                                   photoId: photoId,
                                   commentId: commentId,
                                   actorName: user.name)
    }

    func observeNotifications(for userId: String, completion: @escaping ([AppNotification]) -> Void) -> ListenerRegistration {
        db.collection("users")
            .document(userId)
            .collection(notificationCollection)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else {
                    completion([])
                    return
                }

                let notifications = documents.compactMap { try? $0.data(as: AppNotification.self) }
                completion(notifications)
            }
    }

    func markNotificationsAsRead(_ ids: [String], for userId: String) async {
        guard !ids.isEmpty else { return }

        let collection = db.collection("users").document(userId).collection(notificationCollection)
        let batch = db.batch()

        ids.forEach { id in
            batch.updateData(["isRead": true], forDocument: collection.document(id))
        }

        do {
            try await batch.commit()
        } catch {
            print("❌ Impossible de marquer les notifications comme lues : \(error)")
        }
    }

    private func persistNotifications(for userIds: [String],
                                       kind: AppNotificationKind,
                                       title: String,
                                       message: String,
                                       challengeId: String?,
                                       challengeTitle: String?,
                                       photoId: String?,
                                       commentId: String?,
                                       actorName: String?) async {
        guard !userIds.isEmpty else { return }

        let timestamp = Timestamp(date: Date())
        let batch = db.batch()

        userIds.forEach { userId in
            let document = db.collection("users")
                .document(userId)
                .collection(notificationCollection)
                .document()

            var data: [String: Any] = [
                "type": kind.rawValue,
                "title": title,
                "message": message,
                "createdAt": timestamp,
                "isRead": false
            ]

            if let challengeId { data["challengeId"] = challengeId }
            if let challengeTitle { data["challengeTitle"] = challengeTitle }
            if let photoId { data["photoId"] = photoId }
            if let commentId { data["commentId"] = commentId }
            if let actorName { data["actorName"] = actorName }

            batch.setData(data, forDocument: document)
        }

        do {
            try await batch.commit()
        } catch {
            print("❌ Erreur lors de l’enregistrement des notifications Firestore : \(error)")
        }
    }

    private func notificationData(kind: AppNotificationKind,
                                  challengeId: String?,
                                  challengeTitle: String?,
                                  photoId: String?,
                                  commentId: String?,
                                  actorName: String?) -> [String: Any] {
        var data: [String: Any] = ["type": kind.rawValue]
        if let challengeId { data["challengeId"] = challengeId }
        if let challengeTitle { data["challengeTitle"] = challengeTitle }
        if let photoId { data["photoId"] = photoId }
        if let commentId { data["commentId"] = commentId }
        if let actorName { data["actorName"] = actorName }
        return data
    }

    private func truncatedComment(_ text: String, limit: Int = 120) -> String {
        guard text.count > limit else { return text }
        let endIndex = text.index(text.startIndex, offsetBy: limit)
        return "\(text[..<endIndex])…"
    }

    private func notificationRoute(from data: [String: Any]) -> NotificationRoute? {
        guard let typeString = data["type"] as? String,
              let kind = AppNotificationKind(rawValue: typeString) else { return nil }

        switch kind {
        case .photoPosted, .like:
            guard let challengeId = data["challengeId"] as? String,
                  let photoId = data["photoId"] as? String else { return nil }
            return .photo(challengeId: challengeId, photoId: photoId, commentId: nil)
        case .comment:
            guard let challengeId = data["challengeId"] as? String,
                  let photoId = data["photoId"] as? String else { return nil }
            let commentId = data["commentId"] as? String
            return .photo(challengeId: challengeId, photoId: photoId, commentId: commentId)
        case .reminder:
            guard let challengeId = data["challengeId"] as? String else { return nil }
            return .challenge(challengeId: challengeId)
        }
    }

    func fetchOneSignalPushIds(userIds: [String], excludeCurrentUser: Bool = true) async throws -> [String] {
        var playerIds: [String] = []

        for userId in userIds {
            let snap = try await db.collection("users").document(userId).getDocument()

            if let data = snap.data(),
               let playerId = data["onesignalPlayerId"] as? String,
               !playerId.isEmpty {
                playerIds.append(playerId)
                print("✅ Trouvé playerId : \(playerId) pour uid : \(userId)")
            } else {
                print("⚠️ Aucun playerId OneSignal pour uid : \(userId)")
            }
        }

        if excludeCurrentUser {
            return playerIds.filter { $0 != currentOneSignalPushId }
        }

        return playerIds
    }

    private func sendUrlRequestNotification(payload: [String: Any]) {
        let url = URL(string: "https://onesignal.com/api/v1/notifications")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic os_v2_app_ldirud6pczcvlmsyzfgwv6qk6mxcvfhmnbcuijvwhdlo64mje7ovicdd6wbq36toy6lyley5gnfxdnz3wi2q3dzvehqlyjk5meujeni", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Push notification erreur : \(error)")
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("OneSignal status : \(httpResponse.statusCode)")
            }
            if let data = data, let body = String(data: data, encoding: .utf8) {
                print("Réponse OneSignal : \(body)")
            }
        }.resume()
    }
}

//class PushObserver: NSObject, OSPushSubscriptionObserver {
//    func onPushSubscriptionDidChange(state: OSPushSubscriptionChangedState) {
//        guard let playerId = state.current.id else {
//            print("⚠️ Aucun playerId détecté.")
//            return
//        }
//
//        print("🔄 Nouveau playerId détecté : \(playerId)")
//
//        if let userId = UserManager.shared.currentUser?.id {
//            Firestore.firestore().collection("users").document(userId).updateData([
//                "onesignalPlayerId": playerId
//            ]) { error in
//                if let error = error {
//                    print("❌ Erreur Firestore : \(error)")
//                } else {
//                    print("✅ playerId mis à jour")
//                }
//            }
//        }
//    }
//}
