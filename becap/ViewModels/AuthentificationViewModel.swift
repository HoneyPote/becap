//
//  AuthentificationViewModel.swift
//  becap
//
//  Created by Victor Derveaux on 17/07/2025.
//

import Foundation

class AuthentificationViewModel: ObservableObject {
    @Published var authError: String? = nil
    @Published var isAuthenticated: Bool = false

    private let accountManager: AccountManagerProtocol = AccountManager()

    init() {}

    func login(email: String, password: String) {
        Task {
            do {
                _ = try await accountManager.login(email: email, password: password)
                await MainActor.run {
                    isAuthenticated = true
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
                    isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    authError = error.localizedDescription
                }
            }
        }
    }
}
