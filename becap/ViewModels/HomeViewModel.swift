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
    @Published var challengeToReport: Challenge?
    @Published var isSubmittingReport = false
    @Published var reportErrorMessage: String?
    @Published var showReportSuccessToast = false

    private var cancellables = Set<AnyCancellable>()
    private var challengeToQuit: Challenge?

    private let challengeManager: ChallengeManager
    private let reportManager: ReportManagerProtocol
    private var challengeToDelete: Challenge?

    private let lockedShowcaseChallenge = Challenge(
        title: "Challenge Premium",
        duration: 7,
        startDate: Date(),
        creatorUID: "premium@becap",
        participantUids: [],
        category: .sport,
        notificationsConfig: nil,
        code: nil,
        jokerConfiguration: nil,
        isPremium: true,
        price: 4.99,
        infoText: "Programme premium guidé avec vidéos, rappel quotidien et récompenses exclusives pour garder la motivation.",
        infoVideoURL: nil
    )

    init(challengeManager: ChallengeManager = ChallengeManager.shared,
         reportManager: ReportManagerProtocol = ReportManager.shared) {
        self.challengeManager = challengeManager
        self.reportManager = reportManager

        observeChallengesChanges()
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

    var premiumChallenges: [Challenge] {
        challenges.filter { $0.isPremium ?? false }
    }

    var standardChallenges: [Challenge] {
        challenges.filter { !($0.isPremium ?? false) }
    }

    // MARK: - Paywall
    func isLocked(_ challenge: Challenge, hasPremium: Bool) -> Bool {
        if challenge.id == lockedShowcaseChallenge.id {
            return true
        }

        return challenge.isLocked(for: challengeManager.currentUser?.id, hasPremium: hasPremium)
    }

    func unlockChallenge(_ challenge: Challenge) async throws {
        guard let userId = challengeManager.currentUser?.id else {
            throw ChallengeManagerError.userNotLoggedIn
        }

        var updatedChallenge = challenge
        if !updatedChallenge.participantUids.contains(userId) {
            updatedChallenge.participantUids.append(userId)
        }

        try await challengeManager.joinChallenge(updatedChallenge, userId: userId)
    }
}

// MARK: - Observers
extension HomeViewModel {
    private func observeChallengesChanges() {
        challengeManager.$challenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] challenges in
                var sorted = challenges.sorted(by: {
                    // Ordre du tri : les actifs en premiers et date de création de la plus récente avant
                    guard $0.status == $1.status else { return $0.status == .active && $1.status == .finished }

                    return $0.startDate > $1.startDate
                })

                if let self, !hasLockedShowcase(in: sorted) {
                    sorted.insert(lockedShowcaseChallenge, at: 0)
                }

                self?.challenges = sorted
            }
            .store(in: &cancellables)
    }

    private func hasLockedShowcase(in challenges: [Challenge]) -> Bool {
        challenges.contains(where: { $0.id == lockedShowcaseChallenge.id || ($0.isPremium ?? false) })
    }
}
