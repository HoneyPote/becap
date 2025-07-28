//
//  MainTabViewModel.swift
//  becap
//
//  Created by Victor Derveaux on 28/07/2025.
//

import SwiftUI

class MainTabViewModel: ObservableObject {
    @Published var challengesDoneFetching: Bool = false

    private var challengeManager: ChallengeManager

    init(challengeManager: ChallengeManager = ChallengeManager.shared) {
        self.challengeManager = challengeManager
    }

    func fetchFilteredChallenges() {
        Task {
            try await challengeManager.fetchAndFilterChallenges()
            await MainActor.run {
                self.challengesDoneFetching = true
            }
        }
    }
}

