//
//  AppState.swift
//  becap
//
//  Created by Victor Derveaux on 25/07/2025.
//

import Foundation

class AppState: ObservableObject {
    static let shared = AppState()

    private enum StorageKeys {
        static let hasAcceptedLegal = "becap.hasAcceptedLegal"
    }

    @Published var sessionID = UUID()
    @Published var isLoggedIn: Bool = false
    @Published var hasAcceptedLegal: Bool {
        didSet {
            UserDefaults.standard.set(hasAcceptedLegal, forKey: StorageKeys.hasAcceptedLegal)
        }
    }

    private init() {
        self.hasAcceptedLegal = UserDefaults.standard.bool(forKey: StorageKeys.hasAcceptedLegal)
    }

    func acceptLegalDocuments() {
        hasAcceptedLegal = true
    }
}
