//
//  NewChallengeViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 28/07/2025.
//

import SwiftUI
import UserNotifications

class NewChallengeViewModel: ObservableObject {
    private static let defaultDuration = 30
    private static let defaultPremiumPrice: Double = 4.99

    @Published var nom: String = ""
    @Published var duree: Int = defaultDuration {
        didSet { updateSuggestedJokersIfNeeded() }
    }
    @Published var heureNotification: Date = Date()
    @Published var isLoading: Bool = false
    @Published var nombreJokers: Int = NewChallengeViewModel.suggestedJokerCount(for: defaultDuration) {
        didSet {
            if shouldIgnoreJokerUpdate {
                shouldIgnoreJokerUpdate = false
            } else if nombreJokers != oldValue {
                userCustomizedJokerCount = true
            }
        }
    }
    @Published var categorie: ChallengeCategory = .autre
    @Published var isPremium: Bool = false
    @Published var premiumPrice: Double = NewChallengeViewModel.defaultPremiumPrice

    private let currentUser: User?
    private let isInfluencer: Bool

    private let accountManager: AccountManager
    private let challengeManager: ChallengeManager
    private let alertManager: GlobalAlertManager

    var trimmedNom: String {
        nom.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isFormValid: Bool {
        !trimmedNom.isEmpty
    }

    init(userManager: UserManagerProtocol = UserManager.shared,
         accountManager: AccountManager = AccountManager(),
         challengeManager: ChallengeManager = ChallengeManager.shared,
         alertManager: GlobalAlertManager = GlobalAlertManager.shared) {
        self.currentUser = userManager.currentUser
        self.accountManager = accountManager
        self.challengeManager = challengeManager
        self.alertManager = alertManager
        self.isInfluencer = currentUser?.isInfluencer ?? false
    }

    func createChallenge(completion: @escaping (Bool) -> Void) {
        isLoading = true

        guard let currentUser, let currentUserId = currentUser.id else {
            isLoading = false
            completion(false)
            return
        }

        let newChallenge = buildNewChallenge(userId: currentUserId)

        Task {
            do {
                guard let newChallenge = try await challengeManager.createChallenge(newChallenge) else { return }

                try await challengeManager.createNewParticipantProgress(userId: currentUserId,
                                                                        challenge: newChallenge)

                await challengeManager.assignCreationMedalsToUser(currentUserId)

                try await refreshUserMedals(userId: currentUserId)

                await MainActor.run {
                    //self.challengeManager.participants[newChallengeId] = [userProgress] // 
                    self.isLoading = false
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    completion(false)
                }
            }
        }
    }

    // MARK: - Private functions

    private func refreshUserMedals(userId: String) async throws {
        Task {
            guard let newUser = try await accountManager.updateCurrentUser(with: userId) else { return }

            await MainActor.run {
                // 🎖️ Affiche les médailles gagnées aujourd'hui
                let today = Calendar.current.startOfDay(for: Date())
                for medal in newUser.medals ?? [] {
                    if Calendar.current.isDate(medal.achievedDate, inSameDayAs: today) {
                        alertManager.show(medal: medal, challengeId: medal.challengeId)
                    }
                }
            }
        }
    }

    private func buildNewChallenge(userId: String) -> Challenge {
        let config: [ChallengeNotification] = (0..<duree).map {
            ChallengeNotification(dayIndex: $0, times: [heureNotification])
        }
        let code = String((0..<6).compactMap { _ in "0123456789".randomElement() })

        let jokerConfig = nombreJokers > 0 ? ChallengeJokerConfiguration(jokersPerParticipant: nombreJokers) : nil

        return Challenge(title: nom,
                         duration: duree,
                         startDate: Date(),
                         creatorUID: userId,
                         participantUids: [userId],
                         category: categorie,
                         notificationsConfig: config,
                         code: code,
                         jokerConfiguration: jokerConfig,
                         isPremium: isPremium && isInfluencer,
                         price: isPremium && isInfluencer ? premiumPrice : nil,
                         infoText: nil,
                         infoVideoURL: nil,
                         premiumAttachments: [],
                         premiumContent: [])
    }

    private func updateSuggestedJokersIfNeeded() {
        guard !userCustomizedJokerCount else { return }

        shouldIgnoreJokerUpdate = true
        nombreJokers = NewChallengeViewModel.suggestedJokerCount(for: duree)
    }

    private static func suggestedJokerCount(for duration: Int) -> Int {
        switch duration {
        case ..<7:
            return 0
        case 7:
            return 1
        case 8...14:
            return 2
        case 15...21:
            return 3
        case 22...35:
            return 4
        default:
            return max(4, Int(round(Double(duration) / 7.0)))
        }
    }

    // MARK: - Premium controls
    var canCreatePremium: Bool { isInfluencer }

    private var userCustomizedJokerCount = false
    private var shouldIgnoreJokerUpdate = false
}
