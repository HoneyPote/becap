//
//  NewDefiViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 25/07/2025.
//
import SwiftUI

@MainActor
final class NewDefiViewModel: ObservableObject {
    @Published var nom: String = ""
    @Published var duree: Int = 30
    @Published var heureNotification: Date = Date()
    @Published var isLoading: Bool = false

    private let currentUser: User?
    private let challengeManager: ChallengeManager

    var isFormValid: Bool {
        !nom.isEmpty
    }

    init(userManager: UserManagerProtocol = UserManager.shared,
         challengeManager: ChallengeManager = ChallengeManager.shared) {
        self.currentUser = userManager.currentUser
        self.challengeManager = challengeManager
    }

    func createChallenge(completion: @escaping (Bool) -> Void) {
        guard let currentUser = currentUser, let uid = currentUser.id else {
            completion(false)
            return
        }

        isLoading = true

        let config: [ChallengeNotification] = (0..<duree).map {
            ChallengeNotification(dayIndex: $0, times: [heureNotification])
        }

        let code = String((0..<6).compactMap { _ in "0123456789".randomElement() })

        let newChallenge = Challenge(
            id: nil,
            title: nom,
            duration: duree,
            startDate: Date(),
            creatorUID: uid,
            participantUids: [uid],
            status: "active",
            notificationsConfig: config,
            code: code
        )

        challengeManager.addNewChallengeToFirestore(newChallenge) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                completion(success)
            }
        }
    }
}
