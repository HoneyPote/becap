//
//  CalendarDetailViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

struct CalendarDetailCell: Hashable {
    var date: Date
    var photos: [ChallengePhoto]
    var isToday: Bool
}

class CalendarDetailViewModel: ObservableObject {
    @Published var allPhotos: [ChallengePhoto] = []
    @Published var selectedParticipant: String? = nil
    @Published var detailCells: [CalendarDetailCell]?
    @Published var doneLoadingPhotos: Bool = false

    private let challengeManager: ChallengeManager

    let challenge: Challenge

    init(challengeManager: ChallengeManager = ChallengeManager.shared,
         challenge: Challenge) {
        self.challengeManager = challengeManager
        self.challenge = challenge
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

    func onAppear() {
        fetchPhotos()
    }

    func buildDetailcells() {
        detailCells = (0..<challenge.duration).compactMap { day in
            guard let date = Calendar.current.date(byAdding: .day, value: day, to: challenge.startDate)
            else { return nil }

            let photos = allPhotos.filter {
                Calendar.current.isDate($0.date, inSameDayAs: date)
//                && (selectedParticipant == nil || $0.authorName == selectedParticipant)
            }

            let isToday = Calendar.current.isDateInToday(date)

            return CalendarDetailCell(date: date, photos: photos, isToday: isToday)
        }
    }

    func fetchPhotos() {
        guard let challengeId = challenge.id else { return }

        self.doneLoadingPhotos = false

        Task {
            let newPhotos = try await challengeManager.loadPhotos(from: challengeId)

            await MainActor.run {
                self.updatePhotos(newPhotos)
                self.doneLoadingPhotos = true
            }
        }
    }

    func deletePhoto(_ photo: ChallengePhoto, completion: @escaping (Bool) -> Void) {
        challengeManager.deletePhoto(photo) { isDeleted in
            if isDeleted {
                let newPhotos = self.allPhotos.filter { $0.id != photo.id }
                self.updatePhotos(newPhotos)
            }
            completion(isDeleted)
        }
    }

    // Appelée quand les photos sont modifiées (ex : suppression)
    private func updatePhotos(_ photos: [ChallengePhoto]) {
        self.allPhotos = photos
        buildDetailcells()
    }
}
