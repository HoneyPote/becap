//
//  CalendarDetailViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

struct Participant: Hashable {
    let id: String
    let name: String
    var medals: [UserMedal]

    static func ==(lhs: Participant, rhs: Participant) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
}

struct CalendarDetailCell: Hashable,Identifiable {
    var date: Date
    var photos: [ChallengePhoto]
    var isToday: Bool

    var id: Date { date }
}

class CalendarDetailViewModel: ObservableObject {
    @Published var allPhotos: [ChallengePhoto] = []
    @Published var detailCells: [CalendarDetailCell]?
    @Published var doneLoadingPhotos: Bool = false
    @Published var selectedPagerInfo: PagerInfo?
    @Published var participants: [Participant] = []

    private let accountManager: AccountManager
    private let challengeManager: ChallengeManager

    var challenge: Challenge
    private  var challengeId: String?

    init(accountManager: AccountManager = AccountManager(),
             challengeManager: ChallengeManager = ChallengeManager.shared,
             challenge: Challenge) {
            self.accountManager = accountManager
            self.challengeManager = challengeManager
            self.challenge = challenge
            self.challengeId = challenge.id
        }

    func fetchInfos() {
        self.doneLoadingPhotos = false

        Task {
            guard let challenge = challengeManager.challenges.first(where: { $0.id == challengeId }) else { return }

                     self.challenge = challenge
            async let photosTask = try fetchPhotos()
            async let allParticipants = try buildParticipants()

            let (photos, participants) = try await (photosTask, allParticipants)

            await MainActor.run {
                self.participants = participants
                self.updatePhotos(photos)
                self.doneLoadingPhotos = true
            }
        }
    }

    func canDeletePhoto(photos: [ChallengePhoto]) -> Bool {
        guard let currentUser = challengeManager.currentUser,
              let currentUserId = currentUser.id
        else { return false }

        return photos.first?.authorUid == currentUserId
    }

    func detailButtonClicked(cell: CalendarDetailCell) {
        if !cell.photos.isEmpty {
            buildPagerInfo(cell: cell)
        }
    }

    func buildDetailcells(for selectedParticipant: Participant? = nil) -> [CalendarDetailCell] {
        return (0..<challenge.duration).compactMap { day in
            guard let date = Calendar.current.date(byAdding: .day, value: day, to: challenge.startDate)
            else { return nil }

            let photos = allPhotos.filter {
                Calendar.current.isDate($0.date, inSameDayAs: date)
                && (selectedParticipant != nil ? $0.authorUid == selectedParticipant?.id : true)
            }
            let isToday = Calendar.current.isDateInToday(date)

            return CalendarDetailCell(date: date, photos: photos, isToday: isToday)
        }
    }

    func deletePhoto(_ photo: ChallengePhoto) {
        guard let challengeId = challenge.id else { return }

        Task {
            do {
                try await challengeManager.deletePhotos([photo], challengeId: challengeId)

                await MainActor.run {
                    self.allPhotos.removeAll(where: { $0.id == photo.id })

                    if let pager = self.selectedPagerInfo {
                        let pagerPhotos = pager.photos.filter { $0.id != photo.id }
                        if pagerPhotos.isEmpty {
                            self.selectedPagerInfo = nil
                        } else {
                            let newIndex = min(pager.index, pagerPhotos.count-1)
                            self.selectedPagerInfo = PagerInfo(photos: pagerPhotos, index: newIndex, date: pager.date)
                        }
                    }
                }
            } catch let error {
                print("Impossible de supprimer la photo. Error : \(error)")
            }
        }
    }

    // MARK: - Private functions

    private func buildParticipants() async throws -> [Participant] {
        var allParticipantsNamesAndMedals: [Participant] = []

        for participantUid in challenge.participantUids {
            guard let currentUser = challengeManager.currentUser,
                  let user = try await accountManager.fetchUser(uid: participantUid) else { continue }

            let participantName = currentUser.id == user.id ? "Moi" : user.name

            allParticipantsNamesAndMedals.append(Participant(id: participantUid, name: participantName, medals: user.medals ?? []))
        }
        return allParticipantsNamesAndMedals
    }

    private func buildPagerInfo(cell: CalendarDetailCell) {
        selectedPagerInfo = PagerInfo(photos: cell.photos, index: 0, date: cell.date)
    }

    private func fetchPhotos() async throws -> [ChallengePhoto] {
        guard let challengeId = challenge.id else { return [] }

        return try await challengeManager.loadPhotos(from: challengeId)
    }

    private func updatePhotos(_ photos: [ChallengePhoto]) {
        self.allPhotos = photos
    }
}

// CalendarDetailViewModel.swift
extension CalendarDetailViewModel {
    func participant(for uid: String) -> Participant? {
        participants.first(where: { $0.id == uid })
    }
}
