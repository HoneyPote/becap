//
//  ParticipantCardView.swift
//  becap
//
//  Created by OpenAI on 05/08/2025.
//

import SwiftUI

struct ParticipantOverviewStats {
    let photosCount: Int
    let likesCount: Int
    let streak: Int
    let validatedDays: Int
    let totalJokers: Int
    let remainingJokers: Int
}

struct ParticipantCardView: View {
    let participant: Participant
    let stats: ParticipantOverviewStats

    @State private var showingMedals = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                ParticipantAvatarView(name: participant.name, photoURL: participant.photoURL)

                VStack(alignment: .leading, spacing: 6) {
                    Text(participant.name)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)
                    Text("Fait partie du défi")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }

            ParticipantStatsGrid(stats: stats)

            if stats.totalJokers > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Jokers restants")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 8) {
                        let displayCount = min(stats.totalJokers, 8)
                        ForEach(0..<displayCount, id: \.self) { index in
                            let isActive = index < min(stats.remainingJokers, displayCount)
                            JokerIconView(size: 26,
                                          fillColor: .white,
                                          isDimmed: !isActive)
                        }

                        if stats.remainingJokers == 0 {
                            Text("Aucun joker restant")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        } else if stats.totalJokers > displayCount {
                            Text("+\(stats.totalJokers - displayCount)")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }

            MedalTriggerRow(
                medalCount: participant.medals.count,
                participantName: participant.name,
                onTap: {
                    if !participant.medals.isEmpty {
                        showingMedals = true
                    }
                }
            )
        }
        .popover(isPresented: $showingMedals, arrowEdge: .top) {
            MedalBubbleView(medals: participant.medals)
        }
    }
}
