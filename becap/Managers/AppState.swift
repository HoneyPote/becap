//
//  AppState.swift
//  becap
//
//  Created by Victor Derveaux on 25/07/2025.
//

import Foundation

enum AppDeepLink: Equatable {
    case calendarPhoto(challengeId: String, photoId: String)
}

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var sessionID = UUID()
    @Published var isLoggedIn: Bool = false
    @Published var deepLink: AppDeepLink?

    func setDeepLink(_ deepLink: AppDeepLink) {
        DispatchQueue.main.async {
            self.deepLink = deepLink
        }
    }

    func clearDeepLink() {
        DispatchQueue.main.async {
            self.deepLink = nil
        }
    }
}
