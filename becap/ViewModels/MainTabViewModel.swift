//
//  MainViewModel.swift
//  becap
//
//  Created by Victor Derveaux on 28/07/2025.
//

import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    @Published var medal: UserMedal?
    @Published var infosDoneFetching: Bool = false

    private let challengeManager: ChallengeManager
    private let notificationManager: NotificationManager
    private let alertManager: GlobalAlertManager

    private var cancellables = Set<AnyCancellable>()

    init(challengeManager: ChallengeManager = ChallengeManager.shared,
         notificationManager: NotificationManager = NotificationManager.shared,
         alertManager: GlobalAlertManager = GlobalAlertManager.shared) {
        self.challengeManager = challengeManager
        self.notificationManager = notificationManager
        self.alertManager = alertManager

        observeMedals()
    }

    func fetchInfos() {
        Task {
            try await challengeManager.fetchAndFilterChallenges()

            await MainActor.run {
                self.refreshPlayerId()
                self.infosDoneFetching = true
            }
        }
    }

    // TODO: Voir pour intégrer un loader personnalisé ici et dans le reste de l'app
    func onChangeOfScenePhase(_ newPhase: ScenePhase) {
        if newPhase == .active {
            fetchInfos()
        }
    }

    func dismissMedalPopup() {
        alertManager.dismiss()
    }

    // MARK: - Private functions

    private func refreshPlayerId() {
        guard let currentUser = challengeManager.currentUser, let userId = currentUser.id else { return }

        notificationManager.setOneSignalPushId(to: userId)
    }
}

// MARK: - Observers
extension MainViewModel {
    private func observeMedals() {
        alertManager.$currentMedal
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentMedal in
                self?.medal = currentMedal
            }
            .store(in: &cancellables)
    }
}
