//
//  SettingsViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var signoutError: String? = nil

    private var cancellables = Set<AnyCancellable>()

    private let accountManager: AccountManagerProtocol
    private let userManager: UserManager

    init(userManager: UserManager = UserManager.shared,
         accountManager: AccountManagerProtocol = AccountManager()) {
        self.userManager = userManager
        self.accountManager = accountManager
        self.currentUser = userManager.currentUser

        observeCurrentUser()
    }

    func signOut() {
        Task {
            do {
                try accountManager.signOut()

                await MainActor.run {
                    AppState.shared.sessionID = UUID()
                    AppState.shared.isLoggedIn = false
                }
            } catch {
                await MainActor.run {
                    signoutError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Observers
extension SettingsViewModel {
    private func observeCurrentUser() {
        userManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentUser in
                self?.currentUser = currentUser
            }
            .store(in: &cancellables)
    }
}
