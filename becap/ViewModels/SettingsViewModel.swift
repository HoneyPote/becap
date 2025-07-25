//
//  SettingsViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var isSignedOut: Bool = false
    @Published var signoutError: String? = nil

    private let accountManager: AccountManagerProtocol

    init(accountManager: AccountManagerProtocol = AccountManager()) {
        self.accountManager = accountManager
    }

    func signOut() {
        Task {
            do {
                try accountManager.signOut()
                await MainActor.run {
                    AppState.shared.isLoggedIn = false
                    isSignedOut = true
                }
            } catch {
                await MainActor.run {
                    signoutError = error.localizedDescription
                }
            }
        }
    }
}
