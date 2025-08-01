//
//  MainTabViewModel.swift
//  becap
//
//  Created by Victor Derveaux on 28/07/2025.
//

import SwiftUI
import Combine

class MainTabViewModel: ObservableObject {
    @Published var medal: UserMedal?
    @Published var infosDoneFetching: Bool = false

    private let challengeManager: ChallengeManager
    private let alertManager: GlobalAlertManager

    private var cancellables = Set<AnyCancellable>()

    init(challengeManager: ChallengeManager = ChallengeManager.shared,
         alertManager: GlobalAlertManager = .shared) {
        self.challengeManager = challengeManager
        self.alertManager = alertManager

        observeMedals()
    }

    func fetchInfos() {
        Task {
            try await challengeManager.fetchAndFilterChallenges()

            await MainActor.run {
                self.infosDoneFetching = true
            }
        }
    }

    func dismissMedalPopup() {
        alertManager.dismiss()
    }
}

// MARK: - Observers
extension MainTabViewModel {
    private func observeMedals() {
        alertManager.$currentMedal
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentMedal in
                self?.medal = currentMedal
            }
            .store(in: &cancellables)
    }
}
