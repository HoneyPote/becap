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

    func shareItems(for challenge: Challenge) -> [Any]? {
        let code = challenge.code ?? ""
        guard let linkURL = universalLinkURL(for: challenge, code: code) else { return nil }

        var messageComponents: [String] = [
            "✨ Découvre \"\(challenge.title)\" sur Becap",
            "",
            "Un calendrier collaboratif pour garder le cap ensemble et célébrer vos réussites quotidiennes.",
            "",
            "Clique sur le lien ci-dessous pour ouvrir l'app.",
            linkURL.absoluteString
        ]

        if let fallbackURL = fallbackUniversalLinkURL(for: challenge, code: code) {
            messageComponents.append(contentsOf: [
                "",
                "🌐 Si Safari n'arrive pas à établir une connexion sécurisée, utilise aussi :",
                fallbackURL.absoluteString
            ])
        }

        if !code.isEmpty {
            messageComponents.append("🔐 Code d'accès : \(code)")
        }

        messageComponents.append(contentsOf: [
            "",
            "Becap – Le rendez-vous collectif de 20h00."
        ])

        let message = messageComponents.joined(separator: "\n")

        #if canImport(UIKit)
        let previewImage = ChallengeSharePreviewBuilder.makePreviewImage(for: challenge, code: code)
        let linkItem = ChallengeShareItem(challenge: challenge,
                                          linkURL: linkURL,
                                          previewImage: previewImage)
        return [previewImage, message, linkItem]
        #else
        return [message, linkURL.absoluteString]
        #endif
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
    private func universalLinkURL(for challenge: Challenge, code: String, host: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = UniversalLinkConfiguration.scheme
        components.host = host ?? UniversalLinkConfiguration.primaryHost
        components.path = UniversalLinkConfiguration.joinPath

        var queryItems: [URLQueryItem] = []
        if !code.isEmpty {
            queryItems.append(URLQueryItem(name: "code", value: code))
        }

        if let id = challenge.id {
            queryItems.append(URLQueryItem(name: "challengeId", value: id))
        }

        guard !queryItems.isEmpty else { return nil }
        components.queryItems = queryItems
        return components.url
    }

    private func fallbackUniversalLinkURL(for challenge: Challenge, code: String) -> URL? {
        guard let fallbackHost = UniversalLinkConfiguration.fallbackHost(excluding: UniversalLinkConfiguration.primaryHost) else {
            return nil
        }

        return universalLinkURL(for: challenge, code: code, host: fallbackHost)
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
