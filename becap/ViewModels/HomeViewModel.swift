//
//  HomeViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI
import Combine

struct BecapChallengeTemplate: Identifiable {
    let id: String
    let title: String
    let category: ChallengeCategory
    let duration: Int
    let defaultNotifications: [Int]
    let type: BecapChallengeType
    let defaultConfiguration: BecapChallengeConfiguration

    var baseChallenge: Challenge {
        Challenge(title: title,
                  duration: duration,
                  startDate: Date(),
                  creatorUID: "becap",
                  adminUids: [],
                  participantUids: [],
                  category: category,
                  defaultNotificationsConfig: defaultNotifications,
                  code: nil,
                  jokerConfiguration: 0)
    }
}

class HomeViewModel: ObservableObject {
    @Published var showQuitAlert = false
    @Published var quitChallengeError: String?
    @Published var challenges: [Challenge] = []
    @Published var becapChallenges: [BecapChallenge] = []
    @Published var challengeToReport: Challenge?
    @Published var isSubmittingReport = false
    @Published var reportErrorMessage: String?
    @Published var showReportSuccessToast = false
    @Published var showRestartSuccessToast = false
    @Published var restartBecapErrorMessage: String?
    @Published private var restartingBecapChallengeIds: Set<String> = []

    private var cancellables = Set<AnyCancellable>()
    private var challengeToQuit: Challenge?

    private let challengeManager: ChallengeManager
    private let reportManager: ReportManagerProtocol
    private let notificationManager: NotificationManager

    var becapTemplates: [BecapChallengeTemplate] = []

    var primaryActiveChallenge: Challenge? {
        let activeChallenges = challenges.filter {
            $0.status == .active && $0.startDate <= Date()
        }
        let activeBecapChallenges = becapChallenges
            .map(\.base)
            .filter { $0.status == .active && $0.startDate <= Date() }

        return (activeChallenges + activeBecapChallenges)
            .sorted { $0.startDate < $1.startDate }
            .first
    }

    // Mocked becap challenge templates
    private func loadBecapChallenges() {
        becapTemplates = [
            BecapChallengeTemplate(id: "plank_template",
                                   title: "Créer défi gainage",
                                   category: .sport,
                                   duration: 30,
                                   defaultNotifications: [480],
                                   type: .plank,
                                   defaultConfiguration: .plank(PlankConfig(secondsPerDay: 60))),

            BecapChallengeTemplate(id: "reading_template",
                                   title: "Créer défi lecture",
                                   category: .reading,
                                   duration: 21,
                                   defaultNotifications: [600],
                                   type: .reading,
                                   defaultConfiguration: .reading(ReadingConfig(pagesPerDay: 20))),

            BecapChallengeTemplate(id: "food_template",
                                   title: "Créer défi nutrition",
                                   category: .food,
                                   duration: 14,
                                   defaultNotifications: [720],
                                   type: .food,
                                   defaultConfiguration: .food(FoodConfig(cheatMealsAllowed: 3))),

            BecapChallengeTemplate(id: "drawing_template",
                                   title: "Créer défi dessin",
                                   category: .drawing,
                                   duration: 30,
                                   defaultNotifications: [1140],
                                   type: .drawing,
                                   defaultConfiguration: .drawing(DrawingConfig(drawingsPerDay: 1)))
        ]
    }

    init(challengeManager: ChallengeManager = ChallengeManager.shared,
         reportManager: ReportManagerProtocol = ReportManager.shared,
         notificationManager: NotificationManager = NotificationManager.shared) {
        self.challengeManager = challengeManager
        self.reportManager = reportManager
        self.notificationManager = notificationManager

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


    func canRestart(_ becapChallenge: BecapChallenge) -> Bool {
        becapChallenge.base.status == .finished && !becapChallenges.contains {
            $0.type == becapChallenge.type && $0.base.status == .active
        }
    }

    func isRestarting(_ becapChallenge: BecapChallenge) -> Bool {
        restartingBecapChallengeIds.contains(becapChallenge.id)
    }

    func restartBecapChallenge(_ becapChallenge: BecapChallenge) {
        guard canRestart(becapChallenge),
              !isRestarting(becapChallenge),
              let currentUserId = challengeManager.currentUser?.id
        else { return }

        restartingBecapChallengeIds.insert(becapChallenge.id)
        restartBecapErrorMessage = nil

        let newChallenge = buildRestartedBecapChallenge(from: becapChallenge, userId: currentUserId)

        Task {
            do {
                guard let createdChallenge = try await challengeManager.createChallenge(newChallenge) else {
                    await finishBecapRestart(for: becapChallenge.id, didSucceed: false)
                    return
                }

                let becapData = BecapChallengeData(challengeId: createdChallenge.id,
                                                   type: becapChallenge.type,
                                                   configuration: becapChallenge.configuration)

                guard try await challengeManager.createBecapChallengeData(becapData) != nil else {
                    await finishBecapRestart(for: becapChallenge.id, didSucceed: false)
                    return
                }

                try await challengeManager.createNewParticipantProgress(userId: currentUserId,
                                                                        challenge: createdChallenge)

                await challengeManager.assignCreationMedalsToUser(currentUserId)
                try await challengeManager.fetchAndFilterChallenges()

                await MainActor.run {
                    self.notificationManager.scheduleDailyNotifications(for: createdChallenge,
                                                                        config: createdChallenge.defaultNotificationsConfig)
                }

                await finishBecapRestart(for: becapChallenge.id, didSucceed: true)
            } catch {
                await finishBecapRestart(for: becapChallenge.id, didSucceed: false)
            }
        }
    }

    func refreshChallenges() {
        Task {
            try await challengeManager.fetchAndFilterChallenges()
        }
    }

    func ensureMembershipIfNeeded(for challengeId: String) async throws -> Bool {
        if challengeManager.challenges.contains(where: { $0.id == challengeId }) {
            try await challengeManager.fetchAndFilterChallenges()
            return false
        }

        return try await challengeManager.ensureMembership(in: challengeId)
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


    private func buildRestartedBecapChallenge(from becapChallenge: BecapChallenge, userId: String) -> Challenge {
        let code = String((0..<6).compactMap { _ in "0123456789".randomElement() })

        return Challenge(title: becapChallenge.title,
                         duration: becapChallenge.duration,
                         startDate: Date(),
                         creatorUID: userId,
                         adminUids: [userId],
                         participantUids: [userId],
                         category: becapChallenge.category,
                         defaultNotificationsConfig: becapChallenge.defaultNotificationsConfig,
                         code: code,
                         jokerConfiguration: becapChallenge.jokerConfiguration)
    }

    @MainActor
    private func finishBecapRestart(for challengeId: String, didSucceed: Bool) {
        restartingBecapChallengeIds.remove(challengeId)

        if didSucceed {
            showRestartSuccessToast = true
        } else {
            restartBecapErrorMessage = "Impossible de relancer ce défi Becap. Veuillez réessayer."
        }
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
