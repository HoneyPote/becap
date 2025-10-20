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
    @Published var premiumChallenges: [PremiumChallenge] = PremiumChallenge.sampleData

    private var cancellables = Set<AnyCancellable>()

    private let challengeManager: ChallengeManager
    private var challengeToDelete: Challenge?

    // Persistance simple locale (tu migreras vers Firestore plus tard)
    private let unlockedKey = "unlockedPremiumChallengeIDs"

    init(challengeManager: ChallengeManager = ChallengeManager.shared) {
        self.challengeManager = challengeManager
        loadUnlocked()
        observeChallengesChanges()
    }

    // MARK: - Premium

    func unlockPremiumChallenge(_ challenge: PremiumChallenge) {
        guard let index = premiumChallenges.firstIndex(where: { $0.id == challenge.id }) else { return }
        premiumChallenges[index].isUnlocked = true
        persistUnlocked()
    }

    func lockPremiumChallenge(_ challenge: PremiumChallenge) {
        guard let index = premiumChallenges.firstIndex(where: { $0.id == challenge.id }) else { return }
        premiumChallenges[index].isUnlocked = false
        persistUnlocked()
    }

    private func persistUnlocked() {
        let ids = premiumChallenges
            .filter { $0.isUnlocked }
            .map { $0.id.uuidString }

        UserDefaults.standard.set(ids, forKey: unlockedKey)
    }

    private func loadUnlocked() {
        let ids = Set(UserDefaults.standard.stringArray(forKey: unlockedKey) ?? [])
        premiumChallenges = premiumChallenges.map { ch in
            var copy = ch
            copy.isUnlocked = ids.contains(ch.id.uuidString)
            return copy
        }
    }

    // MARK: - Delete flow

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
        guard let challenge = challengeToDelete, let challengeId = challenge.id else { return }

        Task {
            do {
                try await challengeManager.deleteChallenge(challengeId)

                await MainActor.run {
                    self.challenges.removeAll { $0.id == challengeId }
                    self.challengeToDelete = nil
                    self.showDeleteAlert = false
                }
            } catch {
                await MainActor.run {
                    self.deleteChallengeError = "Erreur lors de la suppression du défi."
                    self.challengeToDelete = nil
                    self.showDeleteAlert = false
                }
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
                self?.challenges = challenges.sorted(by: {
                    // Ordre du tri : actifs d’abord, puis startDate décroissante
                    guard $0.status == $1.status else {
                        return $0.status == .active && $1.status == .finished
                    }
                    return $0.startDate > $1.startDate
                })
            }
            .store(in: &cancellables)
    }
}

// MARK: - Premium materialization
extension HomeViewModel {
    /// Creates a real Challenge from a premium one and joins the current user
    @MainActor
    func createAndJoinFromPremium(_ premium: PremiumChallenge) async throws -> Challenge {
        guard let userId = challengeManager.currentUser?.id else {
            throw NSError(domain: "Premium", code: 401, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"])
        }

        let newChallenge = PremiumBlueprint.makeChallenge(from: premium, currentUserId: userId)
        // Create in Firestore
        guard let created = try await challengeManager.createChallenge(newChallenge) else {
            throw NSError(domain: "Premium", code: 500, userInfo: [NSLocalizedDescriptionKey: "Création du défi échouée"])
        }

        // Make sure user is participant (if your createChallenge doesn’t already do it)
        try await challengeManager.joinChallenge(created, userId: userId)

        // Optional: refresh local list (Home already observes, but this ensures quick UI update)
        try await challengeManager.fetchAndFilterChallenges()
        return created
    }
}
