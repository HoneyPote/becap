//
//  ReportManager.swift
//  becap
//
//  Created by Adam Mabrouki on 13/08/2025.
//

import Foundation

protocol ReportManagerProtocol {
    func submitChallengeReport(challenge: Challenge, reason: ContentReportReason, details: String?) async throws
}

final class ReportManager: ReportManagerProtocol {
    static let shared = ReportManager()

    private let service: ReportServiceProtocol
    private let userManager: UserManagerProtocol

    init(service: ReportServiceProtocol = ReportService.shared,
         userManager: UserManagerProtocol = UserManager.shared) {
        self.service = service
        self.userManager = userManager
    }

    func submitChallengeReport(challenge: Challenge, reason: ContentReportReason, details: String?) async throws {
        let user = userManager.currentUser

        let report = ContentReport(
            challengeId: challenge.id,
            challengeTitle: challenge.title,
            reporterId: user?.id,
            reporterName: user?.name ?? "Utilisateur inconnu",
            reason: reason,
            details: details?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            createdAt: Date()
        )

        try await service.submitReport(report)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
