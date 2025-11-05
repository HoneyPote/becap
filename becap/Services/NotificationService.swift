//
//  NotificationService.swift
//  becap
//
//  Created by Adam Mabrouki on 18/08/2025.
//

import Foundation
import FirebaseFirestore
import OneSignalFramework

final class NotificationService {
    static let shared = NotificationService()

    private let db: Firestore
    private let userManager: UserManager
    private var pushObserver: PushObserver?

    // MARK: - OneSignal constants
    private let onesignalAppId = "58d11a0f-cf16-4555-b258-c94d6afa0af3"

    private let onesignalRestAuth = "os_v2_app_ldirud6pczcvlmsyzfgwv6qk6oiecbj3sske4ieap7msi543a56yaks3ghbdivkuxfh2hbbtaracfanruth7orseejknhusiijtuxrq"

    init(db: Firestore = .firestore(), userManager: UserManager = .shared) {
        self.db = db
        self.userManager = userManager
    }

    // MARK: - Setup

    func setupOneSignal(didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        OneSignal.initialize(onesignalAppId, withLaunchOptions: launchOptions)

        OneSignal.Notifications.requestPermission({ accepted in
            print("🔔 User accepted notifications: \(accepted)")
        }, fallbackToSettings: false)

        // ✅ Login immédiat si on a déjà l’UID
        if let uid = userManager.currentUser?.id, !uid.isEmpty {
            OneSignal.login(uid)
        } else {
            OneSignal.logout()
        }

        // ✅ Un SEUL observer ici (supprime celui de l’AppDelegate)
        let observer = PushObserver()
        OneSignal.User.pushSubscription.addObserver(observer)
        self.pushObserver = observer

        // ✅ Fallback: persister le playerId s’il arrive un poil plus tard
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            if let uid = self.userManager.currentUser?.id, !uid.isEmpty,
               let pid = OneSignal.User.pushSubscription.id {
                print("✅ [Fallback] playerId OneSignal : \(pid)")
                self.setOneSignalPushId(to: uid)
            } else {
                print("⚠️ [Fallback] Pas de playerId ou pas d’UID pour persister")
            }
        }

        print("📡 OneSignal setup done. id: \(OneSignal.User.pushSubscription.id ?? "nil")")
    }

    var currentOneSignalPushId: String? {
        OneSignal.User.pushSubscription.id
    }

    func loginOneSignalUser(with userId: String) {
        OneSignal.login(userId)
    }

    func logoutOneSignalUser() {
        OneSignal.logout()
    }

    func setOneSignalPushId(to userId: String) {
        guard let oneSignalPushId = currentOneSignalPushId else { return }
        db.collection("users").document(userId).setData(["onesignalPlayerId": oneSignalPushId], merge: true)
    }
    func sendPhotoNotification(to participantIds: [String],
                               authorName: String,
                               challengeTitle: String,
                               challengeId: String,
                               photoId: String) async {
        do {
            // Exclure l’auteur, dédupliquer
            let selfUid = userManager.currentUser?.id
            let externalIds = Array(Set(participantIds.filter { $0 != selfUid }))

            if externalIds.isEmpty {
                print("⚠️ sendPhotoNotification: aucun destinataire (participants == auteur ou vide).")
                return
            }

            // Récupérer playerIds (exclut l’appareil courant)
            let playerIds = try await fetchOneSignalPushIds(userIds: externalIds)

            let headings = [
                "en": "New post in \"\(challengeTitle)\"",
                "fr": "Nouveau post dans \"\(challengeTitle)\""
            ]
            let contents = [
                "en": "\(authorName) added a new photo!",
                "fr": "\(authorName) a posté une nouvelle photo !"
            ]

            print("📬 PHOTO → externalIds=\(externalIds) playerIds=\(playerIds)")

            let deepLink = makePhotoDeepLink(challengeId: challengeId, photoId: photoId)
            let additionalData: [String: Any] = [
                "type": "photo_posted",
                "challengeId": challengeId,
                "photoId": photoId
            ]

            // Passe par le même helper que like/comment
            sendForUser(externalIds: externalIds,
                        playerIds: playerIds,
                        headings: headings,
                        contents: contents,
                        userIdForCleanup: externalIds.first ?? "",
                        context: "sendPhotoNotification",
                        additionalData: additionalData,
                        appUrl: deepLink)
        } catch {
            print("❌ Erreur sendPhotoNotification: \(error)")
        }
    }

    // MARK: - LIKE notification
    func sendLikeNotification(to authorUid: String,
                              from userName: String,
                              challengeTitle: String,
                              challengeId: String,
                              photoId: String) async {
        let playerIds = (try? await fetchOneSignalPushIds(userIds: [authorUid], excludeCurrentUser: false)) ?? []

        let headings = ["en": "New like!", "fr": "Nouvelle mention J’aime !"]
        let contents = ["en": "\(userName) liked your photo in \"\(challengeTitle)\"",
                        "fr": "\(userName) a liké ta photo dans \"\(challengeTitle)\""]

        print("🔔 LIKE → authorUid=\(authorUid) playerIds=\(playerIds)")
        let deepLink = makePhotoDeepLink(challengeId: challengeId, photoId: photoId)
        let additionalData: [String: Any] = [
            "type": "photo_liked",
            "challengeId": challengeId,
            "photoId": photoId
        ]
        sendForUser(externalIds: [authorUid],
                    playerIds: playerIds,
                    headings: headings,
                    contents: contents,
                    userIdForCleanup: authorUid,
                    context: "sendLikeNotification",
                    additionalData: additionalData,
                    appUrl: deepLink)
    }

    // MARK: - COMMENT notification
    func sendCommentNotification(to authorUid: String,
                                 from userName: String,
                                 challengeTitle: String,
                                 commentText: String,
                                 challengeId: String,
                                 photoId: String) async {
        let playerIds = (try? await fetchOneSignalPushIds(userIds: [authorUid], excludeCurrentUser: false)) ?? []

        let headings = ["en": "New comment 💬", "fr": "Nouveau commentaire 💬"]
        let contents = ["en": "\(userName) commented your photo in \"\(challengeTitle)\": \"\(commentText)\"",
                        "fr": "\(userName) a commenté ta photo dans \"\(challengeTitle)\" : \"\(commentText)\""]

        print("🔔 COMMENT → authorUid=\(authorUid) playerIds=\(playerIds)")
        let deepLink = makePhotoDeepLink(challengeId: challengeId, photoId: photoId)
        let additionalData: [String: Any] = [
            "type": "photo_commented",
            "challengeId": challengeId,
            "photoId": photoId
        ]
        sendForUser(externalIds: [authorUid],
                    playerIds: playerIds,
                    headings: headings,
                    contents: contents,
                    userIdForCleanup: authorUid,
                    context: "sendCommentNotification",
                    additionalData: additionalData,
                    appUrl: deepLink)
    }

    // MARK: - Firestore fetch
    func fetchOneSignalPushIds(userIds: [String], excludeCurrentUser: Bool = true) async throws -> [String] {
        var ids: [String] = []
        let currentId = excludeCurrentUser ? userManager.currentUser?.id : nil

        for uid in userIds {
            let snap = try await db.collection("users").document(uid).getDocument()
            guard let data = snap.data(),
                  let pid = data["onesignalPlayerId"] as? String,
                  !pid.isEmpty else {
                print("⚠️ Aucun playerId pour uid=\(uid)")
                continue
            }
            if let currentId, uid == currentId {
                print("ℹ️ Ignoré playerId courant pour \(uid)")
                continue
            }
            ids.append(pid)
            print("✅ Trouvé playerId : \(pid) pour uid : \(uid)")
        }
        return ids
    }

    // MARK: - Core send helpers
    private func makePhotoDeepLink(challengeId: String, photoId: String) -> String {
        var comps = URLComponents()
        comps.scheme = "becap"
        comps.host = "photo"
        comps.queryItems = [
            URLQueryItem(name: "challengeId", value: challengeId),
            URLQueryItem(name: "photoId", value: photoId)
        ]

        return comps.url?.absoluteString ?? "becap://photo?challengeId=\(challengeId)&photoId=\(photoId)"
    }

    private func sendForUser(externalIds: [String],
                             playerIds: [String],
                             headings: [String: String],
                             contents: [String: String],
                             userIdForCleanup: String,
                             context: String,
                             additionalData: [String: Any]? = nil,
                             appUrl: String? = nil) {
        // 1️⃣ D’abord tenter via playerIds (plus simple, pas de target_channel requis)
        if !playerIds.isEmpty {
            var payload: [String: Any] = [
                "app_id": onesignalAppId,
                "include_player_ids": playerIds,
                "headings": headings,
                "contents": contents,
                "ios_sound": "default"
            ]
            if let additionalData { payload["data"] = additionalData }
            if let appUrl { payload["app_url"] = appUrl }
            sendUrlRequestNotification(payload: payload, context: context) { invalid in
                guard !invalid.isEmpty else { return }
                print("⛔️ \(context) invalid_player_ids: \(invalid) → purge + retry via external_id")

                self.handleInvalidPlayerIds(invalid, for: userIdForCleanup)

                // 2️⃣ Retry via alias (external_id) — EXIGE target_channel
                var retryPayload: [String: Any] = [
                    "app_id": self.onesignalAppId,
                    "include_aliases": ["external_id": [userIdForCleanup]],
                    "target_channel": "push",
                    "headings": headings,
                    "contents": contents,
                    "ios_sound": "default"
                ]
                if let additionalData { retryPayload["data"] = additionalData }
                if let appUrl { retryPayload["app_url"] = appUrl }
                self.sendUrlRequestNotification(payload: retryPayload,
                                                context: context + " [retry-alias]") { _ in }
            }
            return
        }

        // 3️⃣ Si aucun playerId dispo, on passe direct par alias (external_id) — avec target_channel
        if !externalIds.isEmpty {
            var payload: [String: Any] = [
                "app_id": onesignalAppId,
                "include_aliases": ["external_id": externalIds],
                "target_channel": "push",
                "headings": headings,
                "contents": contents,
                "ios_sound": "default"
            ]
            if let additionalData { payload["data"] = additionalData }
            if let appUrl { payload["app_url"] = appUrl }
            sendUrlRequestNotification(payload: payload, context: context) { _ in }
            return
        }

        print("⚠️ \(context): aucun target valide (ni playerIds, ni externalIds).")
    }

    private func handleInvalidPlayerIds(_ invalidIds: [String], for userId: String) {
        guard !invalidIds.isEmpty else { return }
        db.collection("users").document(userId).updateData([
            "onesignalPlayerId": FieldValue.delete()
        ]) { err in
            if let err = err {
                print("⚠️ Purge playerId Firestore échouée: \(err)")
            } else {
                print("✅ playerId périmé supprimé pour \(userId)")
            }
        }
    }

    private func sendUrlRequestNotification(payload: [String: Any],
                                            context: String,
                                            onInvalidPlayers: @escaping ([String]) -> Void) {
        let url = URL(string: "https://onesignal.com/api/v1/notifications")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let trimmedKey = onesignalRestAuth.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            print("⚠️ \(context) annulée : clé OneSignal REST manquante.")
            onInvalidPlayers([])
            return
        }

        let authHeader: String
        if trimmedKey.lowercased().hasPrefix("basic ") {
            authHeader = trimmedKey
        } else {
            authHeader = "Basic \(trimmedKey)"
        }
        req.setValue(authHeader, forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err {
                print("❌ \(context) error: \(err)")
                return
            }

            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            print("📦 \(context) status=\(code)")
            print("↪︎ \(context) body=\(body)")

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                onInvalidPlayers([])
                return
            }

            if let errors = json["errors"] as? [String: Any],
               let invalid = errors["invalid_player_ids"] as? [String],
               !invalid.isEmpty {
                onInvalidPlayers(invalid)
            } else {
                onInvalidPlayers([])
            }
            
        }.resume()
    }
}

// MARK: - PushObserver
final class PushObserver: NSObject, OSPushSubscriptionObserver {
    func onPushSubscriptionDidChange(state: OSPushSubscriptionChangedState) {
        guard let playerId = state.current.id else {
            print("⚠️ Aucun playerId détecté.")
            return
        }

        print("🔄 Nouveau playerId détecté : \(playerId)")

        if let userId = UserManager.shared.currentUser?.id {
            Firestore.firestore().collection("users").document(userId)
                .updateData(["onesignalPlayerId": playerId]) { error in
                    if let error = error {
                        print("❌ Erreur Firestore : \(error)")
                    } else {
                        print("✅ playerId mis à jour pour \(userId)")
                    }
                }
        }
    }
}
