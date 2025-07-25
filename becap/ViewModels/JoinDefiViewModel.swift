////
////  JoinDefiViewModelswift
////  becap
////
////  Created by Adam Mabrouki on 23/07/2025.
////
//
//import Foundation
//import SwiftUI
//import FirebaseFirestore
/// MARK: - ViewModel de JoinDefiView
///
///
import SwiftUI
import FirebaseAuth
import FirebaseFirestore


@MainActor
final class JoinDefiViewModel: ObservableObject {
    // Code saisi par l'utilisateur pour rejoindre un défi
    @Published var code: String = ""

    // Liste des défis créés ou rejoints par l'utilisateur
    @Published var userCreatedChallenges: [Challenge] = []

    // Défi sélectionné pour affichage ou partage
    @Published var selectedChallengeToShare: Challenge?

    // État d'affichage de l'alerte
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    /// Rejoint un défi si le code est valide
    func joinChallengeIfCodeValid(challengeManager: ChallengeManager, onSuccess: @escaping () -> Void) async {
        // Vérifie que le code est bien un code à 6 chiffres
        guard code.count == 6 else {
            alert(title: "Code invalide", message: "Le code doit contenir 6 chiffres.")
            return
        }

        // Recharge les défis de l'utilisateur (filtrés + complets)
        await challengeManager.fetchAndFilterChallenges()
        let allChallenges = await challengeManager.fetchAllChallengesOnceAsync()

        // Cherche le défi correspondant au code
        guard let challenge = allChallenges.first(where: { $0.code == code }) else {
            alert(title: "Défi introuvable", message: "Vérifie que le code est correct.")
            return
        }

        // Vérifie que l'utilisateur est bien connecté
        guard let user = challengeManager.currentUser, let userId = user.id else {
            alert(title: "Erreur", message: "Utilisateur non connecté.")
            return
        }

        // Si l'utilisateur ne participe pas encore au défi, on l'ajoute
        if !challenge.participantUids.contains(userId) {
            var updated = challenge
            updated.participantUids.append(userId)

            // MAJ dans Firestore + rechargement local
            await challengeManager.updateChallenge(updated)
            await challengeManager.fetchAndFilterChallenges()

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
    func loadAllUserChallenges(challengeManager: ChallengeManager) async {
        let all = await challengeManager.fetchAllChallengesOnceAsync()
        guard let user = challengeManager.currentUser, let uid = user.id else { return }

        // Filtre les défis liés à l'utilisateur
        let userOwned = all.filter { $0.creatorUID == uid || $0.participantUids.contains(uid) }

        // MAJ des valeurs pour la vue
        DispatchQueue.main.async {
            self.userCreatedChallenges = userOwned
            if self.selectedChallengeToShare == nil {
                self.selectedChallengeToShare = userOwned.first
            }
        }
    }

    /// Déclenche une alerte avec titre et message donnés
    private func alert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
}
