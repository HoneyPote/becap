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
    @Published var totalPostsCount = 0
    @Published var friendsCount = 0

    private var cancellables = Set<AnyCancellable>()

    private let accountManager: AccountManagerProtocol
    private let userManager: UserManager
    private let challengeService: ChallengeService

    init(userManager: UserManager = UserManager.shared,
         accountManager: AccountManagerProtocol = AccountManager(),
         challengeService: ChallengeService = ChallengeService.shared) {
        self.userManager = userManager
        self.accountManager = accountManager
        self.challengeService = challengeService
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

    @MainActor
    func updateProfile(name: String, description: String) async {
        do {
            try await ChallengeService.shared.updateUserProfile(name: name, description: description)
            await reloadUser()
        } catch {
            print("❌ update profile error: \(error)")
        }
    }



    @MainActor
    func refreshProfileStats(challenges: [Challenge]) async {
        guard let currentUserId = currentUser?.id else {
            totalPostsCount = 0
            friendsCount = 0
            return
        }

        let userChallenges = challenges.filter {
            $0.creatorUID == currentUserId || $0.participantUids.contains(currentUserId)
        }

        let computedFriends = Set(
            userChallenges
                .flatMap(\.participantUids)
                .filter { $0 != currentUserId }
        )
        friendsCount = computedFriends.count

        guard !userChallenges.isEmpty else {
            totalPostsCount = 0
            return
        }

        do {
            let postCount = try await withThrowingTaskGroup(of: Int.self) { group in
                for challenge in userChallenges {
                    group.addTask {
                        let posts = try await self.challengeService.fetchPosts(for: challenge.id)
                        return posts.filter { $0.authorUid == currentUserId }.count
                    }
                }

                var total = 0
                for try await count in group {
                    total += count
                }
                return total
            }

            totalPostsCount = postCount
        } catch {
            print("❌ Impossible de charger les photos du profil: \(error)")
            totalPostsCount = 0
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
