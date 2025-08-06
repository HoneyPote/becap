//
//  GridPhotosSheetView.swift
//  becap
//
//  Created by Adam Mabrouki on 01/08/2025.
//
import SwiftUI

struct GridPhotosSheetView: View {
    @ObservedObject private var viewModel: GridPhotosSheetViewModel
    let getParticipant: (String) -> Participant?
    let challengeTitle: String
    let onClose: () -> Void
    @State private var selectedPhoto: ChallengePhoto?
    @State private var pagerInfo: PagerInfo?

    init(cell: CalendarDetailCell,
         getParticipant: @escaping (String) -> Participant?,
         challengeTitle: String,
         onClose: @escaping () -> Void) {
        self._viewModel = ObservedObject(wrappedValue: GridPhotosSheetViewModel(cell: cell))
        self.getParticipant = getParticipant
        self.challengeTitle = challengeTitle
        self.onClose = onClose
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(viewModel.sortedPhotos.sorted(by: { $0.authorName.lowercased() < $1.authorName.lowercased() }), id: \.id) { photo in
                        VStack(spacing: 2) {
                            AsyncImage(url: URL(string: photo.imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(8)

                            HStack(spacing: 4) {
                                Text(photo.authorName)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                if let participant = getParticipant(photo.authorUid),
                                   let latestMedal = participant.medals.sorted(by: { $0.achievedDate > $1.achievedDate }).first {
                                    MedalIconView(iconName: latestMedal.iconName)
                                        .frame(width: 26, height: 26)
                                        .shadow(color: Color.black.opacity(0.13), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                        .onTapGesture {
                            let photosSorted = viewModel.sortedPhotos.sorted(by: { $0.authorName.lowercased() < $1.authorName.lowercased() })
                            if let idx = photosSorted.firstIndex(where: { $0.id == photo.id }) {
                                pagerInfo = PagerInfo(
                                    photos: photosSorted,
                                    index: idx,
                                    date: photo.date // ou la date du jour concerné
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .background(LinearGradient.petrolToSky.ignoresSafeArea())
            .toolbar {
                // Bouton de fermeture à gauche
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.title2.bold())
                            .padding(8)
                            .background(Color.black.opacity(0.22))
                            .clipShape(Circle())
                    }
                }

                // Titre custom au centre
                ToolbarItem(placement: .principal) {
                    Text(viewModel.formattedDate) // Ou ce que tu veux comme titre
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(item: $pagerInfo) { pager in
            CalendarPhotoPagerView(
                challengeTitle: challengeTitle,
                photos: pager.photos,
                startIndex: pager.index,
                canDelete: false,
                getParticipant: getParticipant,
                onDelete: { _ in },
                onClose: { pagerInfo = nil }
            )
        }
    }
}
