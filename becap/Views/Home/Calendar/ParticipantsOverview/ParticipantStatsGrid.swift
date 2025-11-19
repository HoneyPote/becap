//
//  ParticipantStatsGrid.swift
//  becap
//
//  Created by OpenAI on 05/08/2025.
//

import SwiftUI

struct ParticipantStatsGrid: View {
    let stats: ParticipantOverviewStats

    private var gridItems: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 12) {
            StatBadge(title: "Photos", value: "\(stats.postsCount)")
            StatBadge(title: "Likes", value: "\(stats.likesCount)")
            StatBadge(title: "Streak", value: "\(stats.streak) j")
            StatBadge(title: "Validées", value: "\(stats.validatedDays)")
        }
    }
}

private struct StatBadge: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)
            Text(title)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
