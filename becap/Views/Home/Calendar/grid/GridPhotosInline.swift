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

    private var hasPhotos: Bool { !cell.photos.isEmpty }
    private var hasJokers: Bool { !cell.jokers.isEmpty }

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
                VStack(alignment: .leading, spacing: 20) {
                    if hasPhotos {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(Array(photosSorted.enumerated()), id: \.offset) { (idx, photo) in
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
                    } else {
                        Text("Aucune photo partagée ce jour.")
                            .font(.system(.callout, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if hasJokers {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Jokers utilisés")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundColor(.white)

                            ForEach(cell.jokers) { usage in
                                JokerUsageRow(usage: usage)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 420)
        }
    }
}

private struct JokerUsageRow: View {
    let usage: CalendarDayJokerUsage

    private var subtitle: String {
        if usage.declaredByAuthor {
            return "Auto-déclaré par le participant"
        }

        if usage.voteCount == 0 {
            return "Validé par la communauté"
        }

        let names = usage.voterNames
        if names.isEmpty {
            return "Validé par \(usage.voteCount) vote(s)"
        }

        return "Validé par : " + names.joined(separator: ", ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            JokerIconView(size: 30, isDimmed: false)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(usage.participantName)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

