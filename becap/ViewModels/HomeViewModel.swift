//
//  HomeViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var showQuitAlert = false
    @Published var quitChallengeError: String?
    @Published var challenges: [Challenge] = []
    @Published var becapChallenges: [BecapChallenge] = []
    @Published var challengeToReport: Challenge?
    @Published var isSubmittingReport = false
    @Published var reportErrorMessage: String?
    @Published var showReportSuccessToast = false

    private var cancellables = Set<AnyCancellable>()
    private var challengeToQuit: Challenge?

    private let challengeManager: ChallengeManager
    private let reportManager: ReportManagerProtocol

    var createBecapChallenges: [BecapChallenge] = []

    private func loadBecapChallenges() {
        // Base Challenge commun (mock)
        let baseGainage = Challenge(title: "Créer gainage quotidien",
                                    duration: 30,
                                    startDate: Date(),
                                    creatorUID: "becap",
                                    adminUids: [],
                                    participantUids: [],
                                    category: .sport,
                                    defaultNotificationsConfig: [480],
                                    code: nil,
                                    jokerConfiguration: 0)

        let baseLecture = Challenge(title: "Créer lecture quotidienne",
                                    duration: 21,
                                    startDate: Date(),
                                    creatorUID: "becap",
                                    adminUids: [],
                                    participantUids: [],
                                    category: .reading,
                                    defaultNotificationsConfig: [600],
                                    code: nil,
                                    jokerConfiguration: 0)

        let baseFood = Challenge(title: "Créer nutrition quotidienne",
                                 duration: 14,
                                 startDate: Date(),
                                 creatorUID: "becap",
                                 adminUids: [],
                                 participantUids: [],
                                 category: .food,
                                 defaultNotificationsConfig: [720],
                                 code: nil,
                                 jokerConfiguration: 0)

        createBecapChallenges = [
            BecapChallenge(
                base: baseGainage,
                becapData: BecapChallengeData(
                    challengeId: "1",
                    type: .gainage,
                    configuration: .gainage(GainageConfig(secondsPerDay: 60)),
                )
            ),
            BecapChallenge(
                base: baseLecture,
                becapData: BecapChallengeData(
                    challengeId: "2",
                    type: .reading,
                    configuration: .reading(ReadingConfig(pagesPerDay: 20)),
                )
            ),
            BecapChallenge(
                base: baseFood,
                becapData: BecapChallengeData(
                    challengeId: "3",
                    type: .food,
                    configuration: .food(FoodConfig(cheatMealsAllowed: 3)),
                )
            )
        ]
    }

    init(challengeManager: ChallengeManager = ChallengeManager.shared,
         reportManager: ReportManagerProtocol = ReportManager.shared) {
        self.challengeManager = challengeManager
        self.reportManager = reportManager

        loadBecapChallenges()
        observeChallengesChanges()
        observeBecapChallengesChanges()
    }

    func onAppearQuitChallengeError() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.quitChallengeError = nil
            }
        }
    }

    func confirmQuit(_ challenge: Challenge) {
        challengeToQuit = challenge
        showQuitAlert = true
    }

    func quitChallenge() {
        guard let challenge = challengeToQuit,
              let currentUserId = challengeManager.currentUser?.id
        else { return }

        Task {
            do {
                try await challengeManager.removeParticipant(challenge.id, userId: currentUserId)
            }
        }
    }

    func refreshChallenges() {
        Task {
            try await challengeManager.fetchAndFilterChallenges()
        }
    }

    func ensureMembershipIfNeeded(for challengeId: String) async throws {
        if challengeManager.challenges.contains(where: { $0.id == challengeId }) {
            try await challengeManager.fetchAndFilterChallenges()
            return
        }

        try await challengeManager.ensureMembership(in: challengeId)
    }

    func cancelQuit() {
        challengeToQuit = nil
        showQuitAlert = false
    }

    func presentReport(for challenge: Challenge) {
        challengeToReport = challenge
        reportErrorMessage = nil
    }

    func cancelReport() {
        challengeToReport = nil
        isSubmittingReport = false
        reportErrorMessage = nil
    }

    func submitReport(reason: ContentReportReason, details: String) {
        guard let challenge = challengeToReport else { return }

        isSubmittingReport = true
        reportErrorMessage = nil

        Task {
            do {
                try await reportManager.submitChallengeReport(challenge: challenge, reason: reason, details: details)

                await MainActor.run {
                    self.isSubmittingReport = false
                    self.challengeToReport = nil
                    self.showReportSuccessToast = true
                }
            } catch {
                await MainActor.run {
                    self.isSubmittingReport = false
                    self.reportErrorMessage = "Impossible d’envoyer le signalement. Veuillez réessayer."
                }
            }
        }
    }
}

// MARK: - Observers
extension HomeViewModel {
    private func observeChallengesChanges() {
        challengeManager.$challenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] challenges in
                self?.challenges = challenges.sorted(by: {
                    // Ordre du tri : les actifs en premiers et date de création de la plus récente avant
                    guard $0.status == $1.status else { return $0.status == .active && $1.status == .finished }

                    return $0.startDate > $1.startDate
                })
            }
            .store(in: &cancellables)
    }

    private func observeBecapChallengesChanges() {
        challengeManager.$becapChallenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] becapChallenges in
                self?.becapChallenges = becapChallenges.sorted(by: {
                    // Ordre du tri : les actifs en premiers et date de création de la plus récente avant
                    guard $0.base.status == $1.base.status else { return $0.base.status == .active && $1.base.status == .finished }

                    return $0.startDate > $1.startDate
                })
            }
            .store(in: &cancellables)
    }
}
