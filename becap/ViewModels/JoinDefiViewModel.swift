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
    }

    func onAppear() {
        observeChallengesChanges()
    }

    /// Rejoint un défi si le code est valide
    func joinChallengeIfCodeValid(onSuccess: @escaping () -> Void) async throws {
        // Vérifie que le code est bien un code à 6 chiffres
        guard code.count == 6 else {
            alert(title: "Code invalide", message: "Le code doit contenir 6 chiffres.")
            return
        }

        // Recharge les défis de l'utilisateur (filtrés + complets)
        let allChallenges = await challengeManager.fetchAllChallengesOnceAsync()

        // Cherche le défi correspondant au code
        guard let challenge = allChallenges.first(where: { $0.code == code }) else {
            alert(title: "Défi introuvable", message: "Vérifie que le code est correct.")
            return
        }

        // Vérifie que l'utilisateur est bien connecté
        guard let user = currentUser, let userId = user.id else {
            alert(title: "Erreur", message: "Utilisateur non connecté.")
            return
        }

        // Si l'utilisateur ne participe pas encore au défi, on l'ajoute
        if !challenge.participantUids.contains(userId) {
            var updated = challenge
            updated.participantUids.append(userId)

            // MAJ dans Firestore + rechargement local
            await challengeManager.updateChallenge(updated)
            try await challengeManager.fetchAndFilterChallenges()

            // Petit délai avant de naviguer
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onSuccess()
            }
        } else {
            // Utilisateur déjà membre du défi
            alert(title: "Déjà membre", message: "Tu fais déjà partie de ce défi.")
        }
    }

    /// Charge tous les défis où l'utilisateur participe ou qu’il a créés
    func observeChallengesChanges() {
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

    /// Déclenche une alerte avec titre et message donnés
    private func alert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
}
