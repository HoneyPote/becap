//
//  AuthentificationViewModel.swift
//  becap
//
//  Created by Victor Derveaux on 17/07/2025.
//

import Foundation

class AuthentificationViewModel: ObservableObject {
    @Published var authError: String? = nil

    private let accountManager: AccountManagerProtocol

    init(accountManager: AccountManagerProtocol = AccountManager()) {
        self.accountManager = accountManager
    }

    func login(email: String, password: String) {
        Task {
            do {
                _ = try await accountManager.login(email: email, password: password)
                await MainActor.run {
                    AppState.shared.isLoggedIn = true
                }
            } catch {
                await MainActor.run {
                    authError = error.localizedDescription
                }
            }
        }
    }

    func register(email: String, password: String, name: String) {
        Task {
            do {
                _ = try await accountManager.register(email: email, password: password, name: name)
                await MainActor.run {
                    AppState.shared.isLoggedIn = true
                }
            } catch {
                await MainActor.run {
                    authError = error.localizedDescription
                }
            }
        }
    }
}
