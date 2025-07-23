//
//  CalendarDetailViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

class CalendarDetailViewModel: ObservableObject {
    let challenge: Challenge
    @Published var allPhotos: [ChallengePhoto]
    @Published var selectedParticipant: String? = nil

    init(challenge: Challenge, photos: [ChallengePhoto]) {
        self.challenge = challenge
        self.allPhotos = photos
    }

    // Liste des participants uniques du défi (pour le filtre)
    var uniqueParticipants: [String] {
        Set(
            allPhotos
                .filter { $0.challengeId == challenge.id } // ← à adapter !
                .map { $0.authorName }
        )
        .sorted()
    }

    // Appelée quand les photos sont modifiées (ex : suppression)
    func updatePhotos(_ photos: [ChallengePhoto]) {
        self.allPhotos = photos
    }
}
