//
//  MedalTriggerRow.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//

import SwiftUI

struct MedalTriggerRow: View {
    let medalCount: Int
    let participantName: String
    let progress: ParticipantProgress?
    let challenge: Challenge?
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

            if medalCount > 0 || progress != nil {
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
                .buttonStyle(.plain)
                .accessibilityLabel("Voir les médailles de \(participantName)")
            }
        }
    }

    private var medalSubtitle: String {
        if let progress,
           let challenge,
           let next = MedalCatalog.nextStreakDefinition(for: progress, challenge: challenge),
           let target = next.streakDays {
            return "Prochaine: \(next.name) • \(progress.currentStreak)/\(target)"
        }

        return medalCount == 0 ? "Aucune médaille pour le moment" : "\(medalCount) médailles"
    }
}

struct MedalBubbleView: View {
    let medals: [UserMedal]
    var progress: ParticipantProgress? = nil
    var challenge: Challenge? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Médailles")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            Divider()
                .background(Color.white.opacity(0.3))

            if let progress, let challenge {
                MedalProgressCard(progress: progress, challenge: challenge)
            }

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

            if let challenge {
                MedalCollectionGrid(definitions: MedalCatalog.streakDefinitions(for: challenge) + [MedalCatalog.completionDefinition],
                                    earnedMedals: medals)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)
    }
}

struct MedalProgressCard: View {
    let progress: ParticipantProgress
    let challenge: Challenge

    private var nextMedal: MedalDefinition? {
        MedalCatalog.nextStreakDefinition(for: progress, challenge: challenge)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Progression")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundColor(.white)

            Text("Série actuelle: \(progress.currentStreak) jour\(progress.currentStreak > 1 ? "s" : "")")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            if let nextMedal, let target = nextMedal.streakDays {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        MedalIconView(iconName: nextMedal.iconName)
                            .frame(width: 20, height: 20)
                        Text("Prochaine: \(nextMedal.name)")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(.white)
                    }

                    ProgressView(value: Double(progress.currentStreak), total: Double(target))
                        .tint(.yellow)

                    Text("Plus que \(max(target - progress.currentStreak, 0)) jour\(target - progress.currentStreak > 1 ? "s" : "")")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            } else {
                Text("Toutes les médailles de série sont débloquées 🎉")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct MedalCollectionGrid: View {
    let definitions: [MedalDefinition]
    let earnedMedals: [UserMedal]

    private var earnedNames: Set<String> {
        Set(earnedMedals.map(\.name))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Collection")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 12) {
                ForEach(definitions) { definition in
                    let unlocked = earnedNames.contains(definition.name)
                    VStack(spacing: 6) {
                        MedalIconView(iconName: definition.iconName)
                            .frame(width: 24, height: 24)
                            .padding(10)
                            .background(Color.white.opacity(unlocked ? 0.18 : 0.08))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(definition.tier.tintColor.opacity(unlocked ? 0.7 : 0.2), lineWidth: 1)
                            )
                            .opacity(unlocked ? 1 : 0.35)

                        Text(definition.name)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.white.opacity(unlocked ? 0.8 : 0.4))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension MedalTier {
    var tintColor: Color {
        switch self {
        case .bronze:
            return Color(red: 205/255, green: 127/255, blue: 50/255)
        case .silver:
            return Color(red: 192/255, green: 192/255, blue: 192/255)
        case .gold:
            return Color(red: 212/255, green: 175/255, blue: 55/255)
        case .platinum:
            return Color(red: 122/255, green: 223/255, blue: 255/255)
        }
    }
}
