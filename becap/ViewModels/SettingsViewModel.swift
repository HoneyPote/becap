//
//  SettingsViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

//
//  SettingsViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var selectedChallenge: Challenge?
    @Published private(set) var challenges: [Challenge] = []
    @Published var isSignedOut: Bool = false
    @Published var signoutError: String? = nil

    private var challengeManager: ChallengeManager
    private let accountManager: AccountServiceProtocol = AccountService()

    init(challengeManager: ChallengeManager) {
        self.challengeManager = challengeManager
        self.challenges = challengeManager.challenges
        // Sélectionne le premier challenge par défaut si dispo
        if let first = challenges.first {
            selectedChallenge = first
        }
    }

    func refresh() {
        challenges = challengeManager.challenges
        if selectedChallenge == nil, let first = challenges.first {
            selectedChallenge = first
        }
    }

    // Pour le picker ou accès direct
    var availableChallenges: [Challenge] { challenges }

    // Utilisé pour le bouton notifications
    var currentChallenge: Challenge? {
        selectedChallenge ?? challenges.first
    }

    func signOut() {
        Task {
            do {
                try accountManager.signOut()
                await MainActor.run {
                    isSignedOut = true
                }
            } catch {
                await MainActor.run {
                    signoutError = error.localizedDescription
                }
            }
        }
    }
}
