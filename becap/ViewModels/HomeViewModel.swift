import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var showDeleteAlert = false
    @Published var lastError: String?
    private var challengeToDelete: Challenge?

    func confirmDelete(_ challenge: Challenge) {
        challengeToDelete = challenge
        showDeleteAlert = true
    }

    func performDelete(manager: ChallengeManager) {
        guard let challenge = challengeToDelete else { return }
        manager.deleteChallenge(challenge) { [weak self] success in
            DispatchQueue.main.async {
                if !success {
                    self?.lastError = "Erreur lors de la suppression du défi."
                }
                self?.showDeleteAlert = false
                self?.challengeToDelete = nil
            }
        }
    }

    func cancelDelete() {
        showDeleteAlert = false
        challengeToDelete = nil
    }
}
