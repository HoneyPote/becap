//
//  CalendarDetailViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

class CalendarDetailViewModel: ObservableObject {
    let defi: Defi
    @Published var allPhotos: [PhotoDefi]
    @Published var selectedParticipant: String? = nil

    init(defi: Defi, photos: [PhotoDefi]) {
        self.defi = defi
        self.allPhotos = photos
    }

    // Liste des participants uniques du défi (pour le filtre)
    var uniqueParticipants: [String] {
        Set(
            allPhotos
                .filter { $0.defiId == defi.id }
                .map { $0.prenomAuteur }
        )
        .sorted()
    }

    // Appelée quand les photos sont modifiées (ex : suppression)
    func updatePhotos(_ photos: [PhotoDefi]) {
        self.allPhotos = photos
    }
}
