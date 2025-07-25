//
//  CalendarDetailViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

class CalendarDetailViewModel: ObservableObject {
    @Published var allPhotos: [ChallengePhoto]
    @Published var selectedParticipant: String? = nil

    private let challengeManager: ChallengeManager

    let challenge: Challenge

    init(challengeManager: ChallengeManager = ChallengeManager.shared,
         challenge: Challenge,
         photos: [ChallengePhoto]) {
        self.challengeManager = challengeManager
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

    func deletePhoto(_ photo: ChallengePhoto, completion: @escaping (Bool) -> Void) {
        challengeManager.deletePhoto(photo) { isDeleted in
            if isDeleted {
                // Mets à jour la liste locale en enlevant la photo supprimée
                let newPhotos = self.allPhotos.filter { $0.id != photo.id }
                self.updatePhotos(newPhotos)
            }
            completion(isDeleted)
        }
    }

    // Appelée quand les photos sont modifiées (ex : suppression)
    private func updatePhotos(_ photos: [ChallengePhoto]) {
        self.allPhotos = photos
    }
}
