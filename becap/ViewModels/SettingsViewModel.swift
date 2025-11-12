//
//  SettingsViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import Foundation
import Combine
import FirebaseAuth

final class SettingsViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var signoutError: String? = nil
    @Published var isDeletingAccount = false
    @Published var accountDeletionError: String?

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

    // MARK: - Avatar

    /// Upload l’avatar, met à jour Firestore via le service,
    /// puis recharge l’utilisateur pour refléter immédiatement la nouvelle URL.
    func updateAvatar(data: Data) async throws {
           let previous = currentUser?.photoURL
           try await ChallengeService.shared.updateUserAvatar(data: data, previousURL: previous)

           // Re-fetch user pour pousser la nouvelle photoURL dans UserManager
           if let uid = Auth.auth().currentUser?.uid {
               _ = try await accountManager.updateCurrentUser(with: uid)
               // Grâce à ton observeCurrentUser(), SettingsView sera rafraîchie
           }
       }

    /// Recharge l’utilisateur depuis la source de vérité (Firestore via AccountManager)
    @MainActor
    func reloadUser() async {
        guard let uid = userManager.currentUser?.id else { return }
        do {
            // Cette méthode existe déjà dans ton projet (utilisée depuis ChallengeManager)
            _ = try await accountManager.updateCurrentUser(with: uid)

            // AccountManager met à jour UserManager.shared.currentUser.
            // Grâce à observeCurrentUser(), currentUser sera rafraîchi automatiquement.
            // On peut toutefois resynchroniser tout de suite :
            self.currentUser = userManager.currentUser
        } catch {
            print("❌ reloadUser error: \(error)")
        }
    }

    // MARK: - Auth

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

    func deleteAccount() {
        guard !isDeletingAccount else { return }

        isDeletingAccount = true
        accountDeletionError = nil

        Task {
            do {
                try await accountManager.deleteAccount()

                await MainActor.run {
                    AppState.shared.sessionID = UUID()
                    AppState.shared.isLoggedIn = false
                    self.isDeletingAccount = false
                }
            } catch {
                await MainActor.run {
                    self.accountDeletionError = error.localizedDescription
                    self.isDeletingAccount = false
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
