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

    private let db: Firestore
    private let userManager: UserManager

    init(db: Firestore = Firestore.firestore(), userManager: UserManager = .shared) {
        self.db = db
        self.userManager = userManager
    }

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

        // 🔄 Ajout de l'observer
        // TODO: À voir si on a besoin de ça, j'ai fait en sorte qu'on refresh le playerId constamment avant l'affichage de MainTabView, est-ce que c'est pas suffisant ? -> En faisant le test de relancer l'application sur deux simu différents avec le même compte, le playerId se change bien même sans l'observer. À confirmer si c'est le bon test à faire.
//        OneSignal.User.pushSubscription.addObserver(PushObserver())
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

    func sendPhotoNotification(to participantIds: [String], authorName: String, challengeTitle: String) async {
        guard let participantOneSignalPushIds = try? await fetchOneSignalPushIds(userIds: participantIds),
              !participantOneSignalPushIds.isEmpty else {
            print("❌ Impossible de trouver le playerId OneSignal pour les participants")
            return
        }

        let payload: [String: Any] = ["app_id": "58d11a0f-cf16-4555-b258-c94d6afa0af3",
                                      "include_player_ids": participantOneSignalPushIds,
                                      "headings": [
                                        "en": "Nouveau post dans \"\(challengeTitle)\"",
                                        "fr": "Nouveau post dans \"\(challengeTitle)\""
                                      ],
                                      "contents": [
                                        "en": "\(authorName) a posté une nouvelle photo !",
                                        "fr": "\(authorName) a posté une nouvelle photo !"
                                      ],
                                      "ios_sound": "default"]

        sendUrlRequestNotification(payload: payload)
    }

    func sendLikeNotification(to authorUid: String, from userName: String, challengeTitle: String) async {
        guard let authorOneSignalPushId = try? await fetchOneSignalPushIds(userIds: [authorUid]).first else {
            print("❌ Impossible de trouver le playerId OneSignal pour l’auteur \(authorUid)")
            return
        }

        let payload: [String: Any] = ["app_id": "58d11a0f-cf16-4555-b258-c94d6afa0af3",
                                      "include_player_ids": [authorOneSignalPushId],
                                      "headings": ["en": "Nouvelle mention J’aime !",
                                                   "fr": "Nouvelle mention J’aime !"],
                                      "contents": ["en": "\(userName) a liké ta photo dans \"\(challengeTitle)\"",
                                                   "fr": "\(userName) a liké ta photo dans \"\(challengeTitle)\""],
                                      "ios_sound": "default"]

        sendUrlRequestNotification(payload: payload)
    }

    func sendCommentNotification(to authorUid: String,
                                 from userName: String,
                                 challengeTitle: String,
                                 commentText: String) async {
        guard let authorOneSignalPushId = try? await fetchOneSignalPushIds(userIds: [authorUid]).first else {
            print("❌ Impossible de trouver le playerId OneSignal pour l’auteur \(authorUid)")
            return
        }

        let payload: [String: Any] = ["app_id": "58d11a0f-cf16-4555-b258-c94d6afa0af3", // ✅ Ton app ID OneSignal
                                      "include_player_ids": [authorOneSignalPushId],
                                      "headings": [
                                        "en": "Nouveau commentaire 💬",
                                        "fr": "Nouveau commentaire 💬"
                                      ],
                                      "contents": [
                                        "en": "\(userName) a commenté ta photo dans \"\(challengeTitle)\" : \"\(commentText)\"",
                                        "fr": "\(userName) a commenté ta photo dans \"\(challengeTitle)\" : \"\(commentText)\""
                                      ],
                                      "ios_sound": "default"]

        sendUrlRequestNotification(payload: payload)
    }

    func fetchOneSignalPushIds(userIds: [String], excludeCurrentUser: Bool = true) async throws -> [String] {
        var playerIds: [String] = []
        let currentUserId = excludeCurrentUser ? userManager.currentUser?.id : nil

        for userId in userIds {
            let snap = try await db.collection("users").document(userId).getDocument()

            guard let data = snap.data(),
                  let playerId = data["onesignalPlayerId"] as? String,
                  !playerId.isEmpty else {
                print("⚠️ Aucun playerId OneSignal pour uid : \(userId)")
                continue
            }

            if let currentUserId, userId == currentUserId {
                print("ℹ️ Ignoré playerId courant pour uid : \(userId)")
                continue
            }

            playerIds.append(playerId)
            print("✅ Trouvé playerId : \(playerId) pour uid : \(userId)")
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
