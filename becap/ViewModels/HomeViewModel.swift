//
//  HomeViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var showDeleteAlert = false
    @Published var deleteChallengeError: String?
    @Published var challenges: [Challenge] = []

    private var cancellables = Set<AnyCancellable>()

    private let challengeManager: ChallengeManager
    private var challengeToDelete: Challenge?

    init(challengeManager: ChallengeManager = ChallengeManager.shared) {
        self.challengeManager = challengeManager

        observeChallengesChanges()
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
                self.challengeToDelete = nil
                self.showDeleteAlert = false
            }
        }
    }

    func refreshChallenges() {
        Task {
            try await challengeManager.fetchAndFilterChallenges()
        }
    }

    func cancelDelete() {
        challengeToDelete = nil
        showDeleteAlert = false
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
}
