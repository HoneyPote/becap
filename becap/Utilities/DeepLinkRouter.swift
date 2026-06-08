//
//  DeepLinkRouter.swift
//  becap
//
//  Created by Victor Derveaux on 09/02/2026.
//

import Foundation

struct PostDeepLink: Equatable {
    let challengeId: String
    let postId: String
}

final class DeepLinkRouter: ObservableObject {
    @Published var pendingCalendarChallengeId: String? = nil
    @Published var pendingPostLink: PostDeepLink? = nil
    @Published var pendingChatChallengeId: String? = nil

    private let notificationCenter: NotificationCenter
    private var notificationObserver: NSObjectProtocol?

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        notificationObserver = notificationCenter.addObserver(forName: .deepLinkRouterHandleExternalURL,
                                                              object: nil,
                                                              queue: .main) { [weak self] notification in
            guard let url = notification.userInfo?["url"] as? URL else { return }
            self?.handle(url: url)
        }
    }

    deinit {
        if let observer = notificationObserver {
            notificationCenter.removeObserver(observer)
        }
    }

    // Appelle ceci depuis .onOpenURL
    func handle(url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              comps.scheme?.lowercased() == "becap" else { return }

        let host = comps.host?.lowercased()

        switch host {
        case "challenge", "join":
            let challengeId = comps.queryItems?.first(where: { $0.name == "challengeId" })?.value
            DispatchQueue.main.async {
                if let challengeId, !challengeId.isEmpty {
                    self.pendingCalendarChallengeId = challengeId
                }
            }

        case "photo":
            let challengeId = comps.queryItems?.first(where: { $0.name == "challengeId" })?.value
            let postId = comps.queryItems?.first(where: { $0.name == "photoId" })?.value

            guard let challengeId, !challengeId.isEmpty,
                  let postId, !postId.isEmpty else { return }

            DispatchQueue.main.async {
                // Définir d'abord la cible photo pour que les observateurs disposent
                // de l'identifiant avant que le challenge ne déclenche la navigation.
                self.pendingPostLink = PostDeepLink(challengeId: challengeId, postId: postId)
                self.pendingCalendarChallengeId = challengeId
            }

        case "chat":
            let challengeId = comps.queryItems?.first(where: { $0.name == "challengeId" })?.value

            DispatchQueue.main.async {
                if let challengeId, !challengeId.isEmpty {
                    self.pendingChatChallengeId = challengeId
                    self.pendingCalendarChallengeId = challengeId
                }
            }

        default:
            break
        }
    }

    func clearChallengeNavigation() {
        pendingCalendarChallengeId = nil
    }

    func clearPostNavigation() {
        pendingPostLink = nil
    }

    func clearChatNavigation() {
        pendingChatChallengeId = nil
    }
}
