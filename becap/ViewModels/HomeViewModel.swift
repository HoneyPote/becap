//
//  HomeViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI
import Combine
import OneSignalFramework
import Firebase

class HomeViewModel: ObservableObject {
    @Published var showDeleteAlert = false
    @Published var deleteChallengeError: String?
    @Published var challenges: [Challenge] = []
    @Published var currentUser: User?

    private var cancellables = Set<AnyCancellable>()

    private let challengeManager: ChallengeManager
    private let userManager: UserManager
    private var challengeToDelete: Challenge?

    init(challengeManager: ChallengeManager = ChallengeManager.shared,
         userManager: UserManager = UserManager.shared) {
        self.challengeManager = challengeManager
        self.userManager = userManager

        observeChallengesChanges()
        observeCurrentUser()
    }

    func onAppearDeleteChallengeError() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.deleteChallengeError = nil
            }
        }
    }

    func confirmDelete(_ challenge: Challenge) {
        challengeToDelete = challenge
        showDeleteAlert = true
    }

    func performDelete() {
        guard let challenge = challengeToDelete else { return }

        challengeManager.deleteChallenge(challenge) { [weak self] success in
            guard let self else { return }

            DispatchQueue.main.async {
                if !success {
                    self.deleteChallengeError = "Erreur lors de la suppression du défi."
                }
                self.showDeleteAlert = false
                self.challengeToDelete = nil
            }
        }
    }

    func refreshChallenges() {
        Task {
            try await challengeManager.fetchAndFilterChallenges()
        }
    }

    func cancelDelete() {
        showDeleteAlert = false
        challengeToDelete = nil
    }
}

// MARK: - Observers
extension HomeViewModel {
    private func observeChallengesChanges() {
        challengeManager.$challenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] challenges in
                self?.challenges = challenges
            }
            .store(in: &cancellables)
    }

    private func observeCurrentUser() {
        userManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.refreshPlayerIdIfNeeded()
            }
            .store(in: &cancellables)
    }

    func refreshPlayerIdIfNeeded() {
        guard let userId = currentUser?.id,
              let playerId = OneSignal.User.pushSubscription.id,
              !playerId.isEmpty else {
            print("⚠️ Pas de playerId ou de userId dispo.")
            return
        }

        Firestore.firestore().collection("users").document(userId).setData([
            "onesignalPlayerId": playerId
        ], merge: true)

        print("🔁 playerId forcé/rafraîchi : \(playerId)")
    }
}
