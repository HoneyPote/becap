//
//  GridPhotosInline.swift
//  becap
//
//  Created by Adam Mabrouki on 04/09/2025.
//

import SwiftUI

// TODO: Découper vue
struct GridPhotosInline: View {
    let cell: CalendarDetailCell
    let challengeTitle: String
    let getParticipant: (String) -> Participant?
    let onClose: () -> Void
    let onOpenPager: (PagerInfo) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    private var photosSorted: [ChallengePhoto] {
        cell.photos.sorted {
            guard $0.authorName != $1.authorName else { return $0.date > $1.date }

            return $0.authorName.localizedCaseInsensitiveCompare($1.authorName) == .orderedAscending
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(cell.date, style: .date)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.25))
                        .clipShape(Circle())
                }
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(photosSorted.enumerated()), id: \.offset) { (idx, photo) in
                        // TODO: Bouton certainement pas nécessaire, VSTack avec onTapAction() plutôt
                        Button {
                            onOpenPager(PagerInfo(photos: photosSorted, index: idx, date: photo.date))
                        } label: {
                            VStack(spacing: 2) {
                                if let url = URL(string: photo.imageUrl) {
                                    AsyncCachedImage(url: url)
                                        .frame(height: 100)
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                        .cornerRadius(8)
                                }

                                HStack(spacing: 4) {
                                    Text(photo.authorName)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    if let participant = getParticipant(photo.authorUid),
                                       let latest = participant.medals.sorted(by: { $0.achievedDate > $1.achievedDate }).first {
                                        MedalIconView(iconName: latest.iconName)
                                            .frame(width: 20, height: 20)
                                            .shadow(color: Color.black.opacity(0.13), radius: 2, x: 0, y: 1)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 420)
        }
    }
}

