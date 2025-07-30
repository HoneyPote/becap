//
//  JoinDefiViewModelswift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

class JoinDefiViewModel: ObservableObject {
    @Published var code: String = ""
    @Published var userCreatedChallenges: [Challenge] = []
    @Published var selectedChallengeToShare: Challenge?
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    private var cancellables = Set<AnyCancellable>()

    private let currentUser: User?
    private let challengeManager: ChallengeManager

    init(userManager: UserManagerProtocol = UserManager.shared,
         challengeManager: ChallengeManager = ChallengeManager.shared) {
        self.currentUser = userManager.currentUser
        self.challengeManager = challengeManager

        observeChallengesChanges()
    }

    // TODO: Supprimer participantUids et récupérer collection participant
    func joinChallengeIfCodeValid(onSuccess: @escaping () -> Void) async throws {
        guard let currentUser, let currentUserId = currentUser.id else {
            alert(title: "Erreur", message: "Utilisateur non connecté.")
            return
        }

        // Vérifie que le code est bien un code à 6 chiffres
        guard code.count == 6 else {
            alert(title: "Code invalide", message: "Le code doit contenir 6 chiffres.")
            return
        }

        Task {
            guard let challenge = try await challengeManager.fetchAllChallenges().first(where: { $0.code == code })
            else {
                alert(title: "Défi introuvable", message: "Vérifie que le code est correct.")
                return
            }

            if !challenge.participantUids.contains(currentUserId) {
                var updatedChallenge = challenge
                updatedChallenge.participantUids.append(currentUserId)

                try await challengeManager.joinChallenge(updatedChallenge, userId: currentUserId)

                // Petit délai avant de naviguer
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onSuccess()
                }
            } else {
                alert(title: "Déjà membre", message: "Tu fais déjà partie de ce défi.")
            }
        }
    }

    private func observeChallengesChanges() {
        challengeManager.$challenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] challenges in
                self?.userCreatedChallenges = challenges
                if self?.selectedChallengeToShare == nil {
                    self?.selectedChallengeToShare = challenges.first
                }
            }
            .store(in: &cancellables)
    }

    private func alert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
}
