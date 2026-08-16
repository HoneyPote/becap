//
//  ShareChallengeViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI
import Combine

final class ShareChallengeViewModel: ObservableObject {
    @Published var challenges: [Challenge] = []
    @Published var selectedChallenge: Challenge?
    @Published var isLoading = false
    @Published var isJoiningByCode = false
    @Published var joinCodeInput: String = ""
    @Published var shakeChallenge = false

    @Published var joinedChallenge: Challenge?

    @Published var showingAlert = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""

    private let challengeManager: ChallengeManager
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedOnce = false

    init(challengeManager: ChallengeManager = ChallengeManager.shared) {
        self.challengeManager = challengeManager
        bindChallengeUpdates()
    }

    func loadChallengesIfNeeded() async {
        guard !hasLoadedOnce else { return }
        await loadChallenges()
    }

    func loadChallenges() async {
        await MainActor.run {
            isLoading = true
        }

        do {
            try await challengeManager.fetchAndFilterChallenges()
            hasLoadedOnce = true
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                self.presentAlert(title: "Oups", message: "Impossible de récupérer tes défis pour le moment. Réessaie plus tard.")
            }
        }
    }

    @MainActor
    func makeShareItems() -> [Any]? {
        guard let challenge = selectedChallenge else {
            triggerChallengeShake()
            return nil
        }

        guard let items = ChallengeShareBuilder.makeShareItems(for: challenge) else {
            presentAlert(title: "Partage indisponible", message: "Nous n'avons pas réussi à générer le lien du défi. Réessaie plus tard.")
            return nil
        }

        return items
    }

    func joinChallengeByCode() async {
        let trimmedCode = joinCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCode.isEmpty else {
            await MainActor.run {
                presentAlert(title: "Code manquant", message: "Entre le code du défi partagé pour le rejoindre.")
            }
            return
        }

        await MainActor.run {
            isJoiningByCode = true
        }

        do {
            let joinedChallenge = try await challengeManager.joinChallenge(withCode: trimmedCode)
            let resolvedChallenge = challengeManager.challenges.first(where: { $0.id == joinedChallenge.id }) ?? joinedChallenge

            await MainActor.run {
                selectedChallenge = resolvedChallenge
                joinCodeInput = ""
                self.joinedChallenge = resolvedChallenge
                presentAlert(title: "Défi rejoint", message: "Tu as bien rejoint \"\(resolvedChallenge.title)\".")
            }
        } catch {
            let message: String

            if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
                message = description
            } else {
                message = "Impossible de rejoindre ce défi pour le moment. Réessaie plus tard."
            }

            await MainActor.run {
                presentAlert(title: "Oups", message: message)
            }
        }

        await MainActor.run {
            isJoiningByCode = false
        }
    }

    // MARK: - Private

    private func bindChallengeUpdates() {
        challengeManager.$challenges
            .sink { [weak self] allChallenges in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    let activeChallenges = allChallenges.filter { $0.status == .active }
                    self.challenges = activeChallenges

                    if let selected = self.selectedChallenge,
                       activeChallenges.contains(selected) {
                        self.selectedChallenge = activeChallenges.first(where: { $0 == selected })
                    } else {
                        self.selectedChallenge = activeChallenges.first
                    }
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func triggerChallengeShake() {
        withAnimation(.default) {
            shakeChallenge = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            Task { @MainActor in
                self?.shakeChallenge = false
            }
        }

        presentAlert(title: "Sélectionne un défi", message: "Choisis d'abord un défi à partager dans la liste.")
    }

    @MainActor
    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}
