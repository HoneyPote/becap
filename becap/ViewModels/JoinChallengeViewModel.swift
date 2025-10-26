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
    private let deepLinkScheme = "becap"
    private let deepLinkHost = "join"

    init(userManager: UserManagerProtocol = UserManager.shared,
         challengeManager: ChallengeManager = ChallengeManager.shared) {
        self.currentUser = userManager.currentUser
        self.challengeManager = challengeManager

        observeChallengesChanges()
    }

    func shareItems(for challenge: Challenge) -> [Any]? {
        let code = challenge.code ?? ""
        let linkURL = deepLinkURL(for: challenge, code: code)

        guard !code.isEmpty || linkURL != nil else { return nil }

        var message = "Je t'invite à rejoindre mon défi \"\(challenge.title)\" sur Becap !"

        if let linkURL {
            message += "\n\nClique sur ce lien pour nous rejoindre directement : \(linkURL.absoluteString)"
        }

        if !code.isEmpty {
            message += "\nCode du défi : \(code)"
        }

        return [message]
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
    private func deepLinkURL(for challenge: Challenge, code: String) -> URL? {
        var components = URLComponents()
        components.scheme = deepLinkScheme
        components.host = deepLinkHost
        components.path = ""

        var queryItems: [URLQueryItem] = []
        if !code.isEmpty {
            queryItems.append(URLQueryItem(name: "code", value: code))
        }

        if let id = challenge.id {
            queryItems.append(URLQueryItem(name: "challengeId", value: id))
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
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
}
