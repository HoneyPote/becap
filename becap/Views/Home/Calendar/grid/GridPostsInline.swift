//
//  GridPostsInline.swift
//  becap
//
//  Created by Adam Mabrouki on 04/09/2025.
//

import SwiftUI

// TODO: Découper vue
struct GridPostsInline: View {
    let cell: CalendarDetailCell
    let postScores: [String: ScoreCard]
    let getParticipant: (String) -> Participant?
    let onClose: () -> Void
    let onOpenPager: (PagerInfo) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    private let jokerColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)

    private var postsSorted: [ChallengePost] {
        cell.posts.sorted {
            guard $0.authorName != $1.authorName else { return $0.date > $1.date }

            return $0.authorName.localizedCaseInsensitiveCompare($1.authorName) == .orderedAscending
        }
    }

    private func thumbnailUrl(media: ChallengeMedia) -> URL? {
        guard let thumbnailUrl = media.thumbnailImageUrl, let url = URL(string: thumbnailUrl) else { return nil }

        return url
    }
    private var hasPosts: Bool { !cell.posts.isEmpty }
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
                VStack {
                    if postsSorted.isEmpty {
                        Text("Aucun post partagé ce jour.")
                            .font(.system(.callout, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .padding([.bottom, .top], 30)
                    } else {
                        VStack(alignment: .leading) {
                            Text("Posts du jour 📸")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundColor(.white)

                            LazyVGrid(columns: columns, spacing: 8) {
                                postsView
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if hasJokers {
                        VStack(alignment: .leading) {
                            Text("Jokers utilisés 🟣")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundColor(.white)

                            LazyVGrid(columns: jokerColumns, spacing: 8) {
                                ForEach(cell.jokers) { usage in
                                    JokerUsageRow(usage: usage)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxHeight: 420)
        }
    }

    private var postsView: some View {
        ForEach(Array(postsSorted.enumerated()), id: \.offset) { (idx, post) in
            // TODO: Bouton certainement pas nécessaire, VSTack avec onTapAction() plutôt
            Button {
                onOpenPager(PagerInfo(posts: postsSorted, index: idx, date: post.date))
            } label: {
                VStack(spacing: 2) {
                    if let thumbnailImageUrl = thumbnailUrl(media: post.media) {
                        AsyncCachedImage(url: thumbnailImageUrl)
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(8)
                            .overlay(alignment: .topTrailing) {
                                if let score = postScores[post.id]?.score {
                                    ScoreBadge(score: score)
                                        .padding(6)
                                }
                            }
                    }

                    HStack(spacing: 4) {
                        Text(post.authorName)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if let participant = getParticipant(post.authorUid),
                           let latest = participant.medals.sorted(by: { $0.achievedDate > $1.achievedDate }).first {
                            MedalIconView(iconName: latest.iconName)
                                .frame(width: 20, height: 20)
                                .shadow(color: Color.black.opacity(0.13), radius: 2, x: 0, y: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ScoreBadge: View {
    let score: Double

    private var scoreText: String {
        if score >= 10 {
            return "10"
        }

        return String(format: "%.1f", score)
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .bold))
            Text(scoreText)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundColor(.white)
        .background(
            LinearGradient(colors: [Color(red: 0.96, green: 0.78, blue: 0.33),
                                    Color(red: 0.94, green: 0.52, blue: 0.32)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        .accessibilityLabel("Score \(scoreText) sur 10")
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
