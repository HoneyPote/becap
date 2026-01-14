//
//  MedalTriggerRow.swift
//  becap
//
//  Created by OpenAI on 05/08/2025.
//

import SwiftUI

struct MedalTriggerRow: View {
    let medalCount: Int
    let participantName: String
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Médailles")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.white.opacity(0.85))

                Text(medalSubtitle)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if medalCount > 0 {
                Button(action: onTap) {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.hapticPlain)
                .accessibilityLabel("Voir les médailles de \(participantName)")
            }
        }
    }

    private var medalSubtitle: String {
        medalCount == 0 ? "Aucune médaille pour le moment" : "\(medalCount) médailles"
    }
}

struct MedalBubbleView: View {
    let medals: [UserMedal]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Médailles")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            Divider()
                .background(Color.white.opacity(0.3))

            if medals.isEmpty {
                Text("Aucune médaille pour le moment")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                ScrollView {
                    ParticipantMedalSection(medals: medals)
                }
                .frame(maxHeight: 260)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)
    }
}
