//
//  JoinChallengeViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

class JoinChallengeViewModel: ObservableObject {
    @Published var userCreatedChallenges: [Challenge] = []
    @Published var selectedChallengeToShare: Challenge?
    @Published var code: String = ""
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showingAlert: Bool = false
    @Published var isJoining: Bool = false

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
    func joinChallenge(onSuccess: @escaping () -> Void) {
        isJoining = true

        guard let currentUser, let currentUserId = currentUser.id else {
            alert(title: "Erreur", message: "Utilisateur non connecté.")
            isJoining = false
            return
        }

        // Vérifie que le code est bien un code à 6 chiffres
        guard code.count == 6 else {
            alert(title: "Code invalide", message: "Le code doit contenir 6 chiffres.")
            isJoining = false
            return
        }

        Task {
            guard let challengeToJoin = try await challengeManager.fetchAllChallenges().first(where: { $0.code == code })
            else {
                alert(title: "Défi introuvable", message: "Vérifie que le code est correct.")
                isJoining = false
                return
            }

            if !challengeToJoin.participantUids.contains(currentUserId) {
                var updatedChallenge = challengeToJoin
                updatedChallenge.participantUids.append(currentUserId)

                try await challengeManager.joinChallenge(updatedChallenge, userId: currentUserId)

                await MainActor.run {
                    self.isJoining = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onSuccess()
                    }
                }
            } else {
                await MainActor.run {
                    self.alert(title: "Déjà membre", message: "Tu fais déjà partie de ce défi.")
                    self.isJoining = false
                }
            }
        }
    }

    // MARK: - Private functions

    private func alert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
}

// MARK: - Observers
extension JoinChallengeViewModel {
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
}
