//
//  HomeViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI
import Combine
import FirebaseFirestore

class HomeViewModel: ObservableObject {
    @Published var showDeleteAlert = false
    @Published var deleteChallengeError: String?
    @Published var challenges: [Challenge] = []
    @Published var challengeToReport: Challenge?
    @Published var isSubmittingReport = false
    @Published var reportErrorMessage: String?
    @Published var showReportSuccessToast = false
    @Published var paywallChallenge: Challenge?
    @Published var isProcessingPayment = false
    @Published var paymentErrorMessage: String?
    @Published var enrollments: [String: ChallengeEnrollment] = [:]
    @Published var paymentStatusMessage: String?
    @Published var isAwaitingBackendConfirmation = false

    private var cancellables = Set<AnyCancellable>()
    private var enrollmentListeners: [String: ListenerRegistration] = [:]

    private let challengeManager: ChallengeManager
    private let reportManager: ReportManagerProtocol
    private let paymentCoordinator: PaymentCoordinator
    private var challengeToDelete: Challenge?

    private let lockedShowcaseChallenge = Challenge(
        _id: "locked-showcase",
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

    private let unlockedPreviewChallenge = Challenge(
        _id: "premium-unlocked-preview",
        title: "Programme Premium (débloqué)",
        duration: 10,
        startDate: Date(),
        creatorUID: "premium@becap",
        participantUids: ["preview-user"],
        category: .sport,
        notificationsConfig: nil,
        code: nil,
        jokerConfiguration: nil,
        isPremium: true,
        price: 4.99,
        infoText: "Aperçu d’un défi premium déjà débloqué pour tester l’UI sans paiement.",
        infoVideoURL: nil
    )

    init(challengeManager: ChallengeManager = ChallengeManager.shared,
         reportManager: ReportManagerProtocol = ReportManager.shared,
         paymentCoordinator: PaymentCoordinator = PaymentCoordinator.shared) {
        self.challengeManager = challengeManager
        self.reportManager = reportManager
        self.paymentCoordinator = paymentCoordinator

        observeChallengesChanges()
    }

    func onAppearDeleteChallengeError() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.deleteChallengeError = nil
            }
        }
    }

    func confirmDelete(_ challenge: Challenge) {
        challengeToDelete = challenge
        showDeleteAlert = true
    }

    func performDelete() {
        guard let challenge = challengeToDelete else { return }

        Task {
            do {
                try await challengeManager.deleteChallenge(challenge.id)

                await MainActor.run {
                    self.challengeToDelete = nil
                    self.showDeleteAlert = false
                }
            } catch {
                await MainActor.run {
                    self.deleteChallengeError = "Erreur lors de la suppression du défi."
                    self.challengeToDelete = nil
                    self.showDeleteAlert = false
                }
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

    func cancelDelete() {
        challengeToDelete = nil
        showDeleteAlert = false
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

    var coachPrograms: [Challenge] {
        challenges.filter { $0.isCoachProgram }
    }

    var creatorPrograms: [Challenge] {
        guard let userId = challengeManager.currentUser?.id else { return [] }
        return challenges.filter { $0.isCoachProgram && (($0.creatorId ?? $0.creatorUID) == userId) }
    }

    var hasCreatorPrograms: Bool { !creatorPrograms.isEmpty }

    // MARK: - Paywall
    func isLocked(_ challenge: Challenge) -> Bool {
        let enrollment = enrollments[challenge.id]
        return challenge.isLocked(for: challengeManager.currentUser?.id, enrollment: enrollment)
    }

    func presentPaywall(for challenge: Challenge) {
        paymentErrorMessage = nil
        paywallChallenge = challenge
        paymentStatusMessage = nil
        isAwaitingBackendConfirmation = false
    }

    func cancelPaywall() {
        isProcessingPayment = false
        paywallChallenge = nil
        isAwaitingBackendConfirmation = false
        paymentStatusMessage = nil
    }

    func simulatePremiumUnlockPreview() {
        guard let premium = premiumChallenges.first ?? challenges.first(where: { $0.isPremium ?? false }) else { return }
        let userId = challengeManager.currentUser?.id ?? "preview-user"

        let previewEnrollment = ChallengeEnrollment.paidPreview(userId: userId, challengeId: premium.id)
        enrollments[premium.id] = previewEnrollment
    }

    func payForSelectedChallenge(using method: PaymentMethod) {
        guard let challenge = paywallChallenge else { return }
        guard let userId = challengeManager.currentUser?.id else {
            paymentErrorMessage = "Connectez-vous pour payer ce défi."
            return
        }
        paymentErrorMessage = nil
        isProcessingPayment = true
        paymentStatusMessage = "Initialisation du paiement…"

        paymentCoordinator.startPayment(for: challenge, userId: userId, method: method) { [weak self] result in
            guard let self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.isProcessingPayment = false
                    self.isAwaitingBackendConfirmation = true
                    self.paymentStatusMessage = "Paiement envoyé. Vérification…"
                case .failure(let error):
                    self.isProcessingPayment = false
                    self.paymentErrorMessage = error.errorDescription
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
                var sorted = challenges.sorted(by: {
                    // Ordre du tri : les actifs en premiers et date de création de la plus récente avant
                    guard $0.status == $1.status else { return $0.status == .active && $1.status == .finished }

                    return $0.startDate > $1.startDate
                })

                if let self, !hasLockedShowcase(in: sorted) {
                    sorted.insert(lockedShowcaseChallenge, at: 0)
                }

                if let self, !sorted.contains(where: { $0.id == unlockedPreviewChallenge.id }) {
                    sorted.insert(unlockedPreviewChallenge, at: 1)
                }

                self?.challenges = sorted
                self?.attachEnrollmentListeners(for: sorted)
            }
            .store(in: &cancellables)
    }

    private func hasLockedShowcase(in challenges: [Challenge]) -> Bool {
        challenges.contains(where: { $0.id == lockedShowcaseChallenge.id || ($0.isPremium ?? false) })
    }

    private func attachEnrollmentListeners(for challenges: [Challenge]) {
        guard let userId = challengeManager.currentUser?.id else { return }

        let premiumIds = Set(challenges.compactMap {
            guard ($0.isPremium ?? false) else { return nil }
            guard $0.id != lockedShowcaseChallenge.id, $0.id != unlockedPreviewChallenge.id else { return nil }
            return $0.id.isEmpty ? nil : $0.id
        })

        // Clean old listeners
        for (challengeId, listener) in enrollmentListeners where !premiumIds.contains(challengeId) {
            listener.remove()
            enrollmentListeners.removeValue(forKey: challengeId)
            enrollments.removeValue(forKey: challengeId)
        }

        for challengeId in premiumIds {
            guard enrollmentListeners[challengeId] == nil else { continue }

            let registration = challengeManager.listenEnrollment(for: challengeId, userId: userId) { [weak self] enrollment in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.enrollments[challengeId] = enrollment
                    self.handleEnrollmentChange(enrollment, for: challengeId)
                }
            }

            if let registration {
                enrollmentListeners[challengeId] = registration
            }
        }
    }

    private func handleEnrollmentChange(_ enrollment: ChallengeEnrollment?, for challengeId: String) {
        guard let enrollment else { return }
        guard let challenge = challenges.first(where: { $0.id == challengeId }) else { return }
        guard let userId = challengeManager.currentUser?.id else { return }

        if enrollment.paymentStatus == .paid {
            Task {
                await MainActor.run {
                    self.isAwaitingBackendConfirmation = false
                    self.paymentStatusMessage = "Paiement confirmé"
                    self.paywallChallenge = nil
                }

                if !challenge.participantUids.contains(userId) {
                    try? await challengeManager.joinChallenge(challenge, userId: userId)
                }
            }
        } else if enrollment.paymentStatus == .failed {
            DispatchQueue.main.async {
                self.paymentErrorMessage = "Le paiement a échoué."
                self.isAwaitingBackendConfirmation = false
            }
        }
    }
}
