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

    // Appelle ceci depuis .onOpenURL et .onContinueUserActivity.
    func handle(url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let route = route(from: comps) else { return }

        switch route {
        case .challenge(let challengeId):
            DispatchQueue.main.async {
                self.pendingCalendarChallengeId = challengeId
            }

        case .photo(let challengeId, let postId):
            DispatchQueue.main.async {
                // Définir d'abord la cible photo pour que les observateurs disposent
                // de l'identifiant avant que le challenge ne déclenche la navigation.
                self.pendingPostLink = PostDeepLink(challengeId: challengeId, postId: postId)
                self.pendingCalendarChallengeId = challengeId
            }
        }
    }

    private enum Route {
        case challenge(String)
        case photo(challengeId: String, postId: String)
    }

    private func route(from comps: URLComponents) -> Route? {
        switch comps.scheme?.lowercased() {
        case "becap":
            return routeFromCustomScheme(comps)
        case "https":
            return routeFromUniversalLink(comps)
        default:
            return nil
        }
    }

    private func routeFromCustomScheme(_ comps: URLComponents) -> Route? {
        switch comps.host?.lowercased() {
        case "challenge", "join":
            return challengeRoute(from: comps)
        case "photo":
            return photoRoute(from: comps)
        default:
            return nil
        }
    }

    private func routeFromUniversalLink(_ comps: URLComponents) -> Route? {
        guard ["becap.app", "www.becap.app"].contains(comps.host?.lowercased() ?? "") else { return nil }

        switch comps.path.lowercased() {
        case "/challenge", "/join":
            return challengeRoute(from: comps)
        case "/photo":
            return photoRoute(from: comps)
        default:
            return nil
        }
    }

    private func challengeRoute(from comps: URLComponents) -> Route? {
        guard let challengeId = comps.queryItems?.first(where: { $0.name == "challengeId" })?.value,
              !challengeId.isEmpty else { return nil }
        return .challenge(challengeId)
    }

    private func photoRoute(from comps: URLComponents) -> Route? {
        guard let challengeId = comps.queryItems?.first(where: { $0.name == "challengeId" })?.value,
              !challengeId.isEmpty,
              let postId = comps.queryItems?.first(where: { $0.name == "photoId" })?.value,
              !postId.isEmpty else { return nil }
        return .photo(challengeId: challengeId, postId: postId)
    }

    func clearChallengeNavigation() {
        pendingCalendarChallengeId = nil
    }

    func clearPostNavigation() {
        pendingPostLink = nil
    }
}
