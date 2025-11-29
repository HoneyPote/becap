//
//  NotificationService.swift
//  becap
//
//  Created by Adam Mabrouki on 18/08/2025.
//

import Foundation
import FirebaseFirestore
import OneSignalFramework

final class NotificationService: NSObject {
    static let shared = NotificationService()

    private let db: Firestore
    private let userManager: UserManager
    private let notificationCenter: NotificationCenter
    private var pushObserver: PushObserver?

    // MARK: - OneSignal constants
    private let onesignalAppId = "58d11a0f-cf16-4555-b258-c94d6afa0af3"


    init(db: Firestore = .firestore(),
         userManager: UserManager = .shared,
         notificationCenter: NotificationCenter = .default) {
        self.db = db
        self.userManager = userManager
        self.notificationCenter = notificationCenter
        super.init()
    }

    // MARK: - Setup

    func setupOneSignal(didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        OneSignal.initialize(onesignalAppId, withLaunchOptions: launchOptions)
        OneSignal.Notifications.addClickListener(self)

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

    func sendPostNotification(challenge: Challenge, authorName: String, postId: String) async {
        do {
            // Exclure l’auteur, dédupliquer
            let allParticipants = challenge.participantUids
            let selfUid = userManager.currentUser?.id
            let externalIds = Array(Set(allParticipants.filter { $0 != selfUid }))

            if externalIds.isEmpty {
                print("⚠️ sendPostNotification: aucun destinataire (participants == auteur ou vide).")
                return
            }

            // Récupérer playerIds (exclut l’appareil courant)
            let playerIds = try await fetchOneSignalPushIds(userIds: externalIds)

            let headings = [
                "en": "New post in \"\(challenge.title)\"",
                "fr": "Nouveau post dans \"\(challenge.title)\""
            ]
            let contents = [
                "en": "\(authorName) added a new post!",
                "fr": "\(authorName) à publié un nouveau post !"
            ]

            print("📬 PHOTO → externalIds=\(externalIds) playerIds=\(playerIds)")

            let deepLink = makePostDeepLink(challengeId: challenge.id, postId: postId)
            let additionalData: [String: Any] = [
                "type": "photo_posted",
                "challengeId": challenge.id,
                "photoId": postId
            ]

            // Passe par le même helper que like/comment
            sendForUser(externalIds: externalIds,
                        playerIds: playerIds,
                        headings: headings,
                        contents: contents,
                        userIdForCleanup: externalIds.first ?? "",
                        context: "sendPostNotification",
                        additionalData: additionalData,
                        appUrl: deepLink)
        } catch {
            print("❌ Erreur sendPostNotification: \(error)")
        }
    }

    // MARK: - LIKE notification
    func sendLikeNotification(to authorUid: String,
                              from userName: String,
                              challenge: Challenge,
                              postId: String) async {
        if authorUid == userManager.currentUser?.id {
            print("ℹ️ sendLikeNotification ignoré: l’auteur est l’utilisateur courant")
            return
        }

        let playerIds = (try? await fetchOneSignalPushIds(userIds: [authorUid], excludeCurrentUser: false)) ?? []

        let headings = ["en": "New like!", "fr": "Nouvelle mention J’aime !"]
        let contents = ["en": "\(userName) liked your post in \"\(challenge.title)\"",
                        "fr": "\(userName) a liké ta post dans \"\(challenge.title)\""]

        print("🔔 LIKE → authorUid=\(authorUid) playerIds=\(playerIds)")
        let deepLink = makePostDeepLink(challengeId: challenge.id, postId: postId)
        let additionalData: [String: Any] = [
            "type": "photo_liked",
            "challengeId": challenge.id,
            "photoId": postId
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
                                 challenge: Challenge,
                                 commentText: String,
                                 postId: String) async {
        if authorUid == userManager.currentUser?.id {
            print("ℹ️ sendCommentNotification ignoré: l’auteur est l’utilisateur courant")
            return
        }

        let playerIds = (try? await fetchOneSignalPushIds(userIds: [authorUid], excludeCurrentUser: false)) ?? []

        let headings = ["en": "New comment 💬", "fr": "Nouveau commentaire 💬"]
        let contents = ["en": "\(userName) commented your post in \"\(challenge.title)\": \"\(commentText)\"",
                        "fr": "\(userName) a commenté ta post dans \"\(challenge.title)\" : \"\(commentText)\""]

        print("🔔 COMMENT → authorUid=\(authorUid) playerIds=\(playerIds)")
        let deepLink = makePostDeepLink(challengeId: challenge.id, postId: postId)
        let additionalData: [String: Any] = [
            "type": "photo_commented",
            "challengeId": challenge.id,
            "photoId": postId
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

    // MARK: - Joker consumed notification
    func sendJokerConsumedNotification(to userId: String,
                                       challenge: Challenge,
                                       postId: String,
                                       remainingJokers: Int) async {
        if userId.isEmpty {
            print("ℹ️ sendJokerConsumedNotification ignoré: userId vide")
            return
        }

        let playerIds = (try? await fetchOneSignalPushIds(userIds: [userId], excludeCurrentUser: false)) ?? []

        let headings = ["en": "Joker used", "fr": "Joker utilisé"]
        let contents = ["en": "Your joker was consumed in \"\(challenge.title)\". Remaining: \(remainingJokers)",
                        "fr": "Ton joker a été utilisé dans \"\(challenge.title)\". Plus que \(remainingJokers) restant(s)"]

        print("🔔 JOKER → userId=\(userId) playerIds=\(playerIds) remaining=\(remainingJokers)")

        let deepLink = makePostDeepLink(challengeId: challenge.id, postId: postId)
        let additionalData: [String: Any] = [
            "type": "joker_consumed",
            "challengeId": challenge.id,
            "photoId": postId
        ]

        sendForUser(externalIds: [userId],
                    playerIds: playerIds,
                    headings: headings,
                    contents: contents,
                    userIdForCleanup: userId,
                    context: "sendJokerConsumedNotification",
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
    private func makePostDeepLink(challengeId: String, postId: String) -> String {
        var comps = URLComponents()
        comps.scheme = "becap"
        comps.host = "photo"
        comps.queryItems = [
            URLQueryItem(name: "challengeId", value: challengeId),
            URLQueryItem(name: "photoId", value: postId)
        ]

        return comps.url?.absoluteString ?? "becap://photo?challengeId=\(challengeId)&photoId=\(postId)"
    }

    private func makeChallengeDeepLink(challengeId: String) -> String {
        var comps = URLComponents()
        comps.scheme = "becap"
        comps.host = "challenge"
        comps.queryItems = [URLQueryItem(name: "challengeId", value: challengeId)]

        return comps.url?.absoluteString ?? "becap://challenge?challengeId=\(challengeId)"
    }

    private func dispatchDeepLinkURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        notificationCenter.post(name: .deepLinkRouterHandleExternalURL,
                                object: nil,
                                userInfo: ["url": url])
    }

    private func sendForUser(externalIds: [String],
                             playerIds: [String],
                             headings: [String: String],
                             contents: [String: String],
                             userIdForCleanup: String,
                             context: String,
                             additionalData: [String: Any]? = nil,
                             appUrl: String? = nil) {

        var payload: [String: Any] = [
            "headings": headings,
            "contents": contents
        ]

        if !playerIds.isEmpty {
            payload["playerIds"] = playerIds
        }

        if !externalIds.isEmpty {
            payload["externalIds"] = externalIds
        }

        if let additionalData {
            payload["additionalData"] = additionalData
        }

        if let appUrl {
            payload["appUrl"] = appUrl
            payload["app_url"] = appUrl
        }

        // On laisse la Cloud Function parler à OneSignal
        sendUrlRequestNotification(payload: payload, context: context) { invalid in
            // Si tu veux plus tard gérer invalid_player_ids renvoyés par la CF, tu pourras le faire ici.
            if !invalid.isEmpty {
                print("⚠️ \(context) invalid_player_ids depuis Cloud Function: \(invalid)")
                // Optionnel : cleanup Firestore ici si tu veux
            }
        }
    }

    private func sendUrlRequestNotification(payload: [String: Any],
                                            context: String,
                                            onInvalidPlayers: @escaping ([String]) -> Void) {
        guard let url = URL(string: "https://us-central1-honeypote-becap.cloudfunctions.net/sendOneSignal") else {
            print("❌ \(context) URL Cloud Function invalide")
            onInvalidPlayers([])
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err {
                print("❌ \(context) error: \(err)")
                onInvalidPlayers([])
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

            // Si OneSignal renvoie encore "errors.invalid_player_ids", on garde ta logique
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

// MARK: - Push click listener
extension NotificationService: OSNotificationClickListener {
    func onClick(event: OSNotificationClickEvent) {
        if let launchURL = event.notification.launchURL,
           let url = URL(string: launchURL) {
            dispatchDeepLinkURL(url.absoluteString)
            return
    }

        guard let data = event.notification.additionalData,
              let type = data["type"] as? String,
              let challengeId = data["challengeId"] as? String else { return }

        if let postId = data["photoId"] as? String,
           !postId.isEmpty,
           type.hasPrefix("photo_") {
            dispatchDeepLinkURL(makePostDeepLink(challengeId: challengeId, postId: postId))
        } else {
            dispatchDeepLinkURL(makeChallengeDeepLink(challengeId: challengeId))
        }
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
