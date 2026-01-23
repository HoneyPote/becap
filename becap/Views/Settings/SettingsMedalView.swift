//
//  SettingsMedalView.swift
//  becap
//
//  Created by OpenAI on 12/02/2026.
//

import SwiftUI

struct SettingsMedalView: View {
    let medals: [UserMedal]
    let challenges: [Challenge]
    let onUnlockSpecialChallenge: () -> Void

    private var totalMedals: Int {
        medals.count
    }

    private var uniqueMedals: Int {
        Set(medals.map(\.name)).count
    }

    private var completionMedalCountForLongChallenges: Int {
        medals.filter { medal in
            guard medal.name == MedalCatalog.completionDefinition.name else { return false }
            guard let challenge = challenges.first(where: { $0.id == medal.challengeId }) else { return false }
            return challenge.duration > 7
        }.count
    }

    private var canUnlockSpecialChallenge: Bool {
        completionMedalCountForLongChallenges >= 3
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 18/255, green: 48/255, blue: 88/255),
                         Color(red: 80/255, green: 38/255, blue: 120/255),
                         Color(red: 35/255, green: 120/255, blue: 166/255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mes médailles")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                        Text("\(totalMedals) obtenues • \(uniqueMedals) uniques")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    Spacer()
                    Image(systemName: "medal.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.yellow)
                }

                SettingsMedalStatsCard(totalMedals: totalMedals,
                                       uniqueMedals: uniqueMedals,
                                       completionCount: completionMedalCountForLongChallenges)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Total par médaille")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)

                    ScrollView {
                        ParticipantMedalSection(medals: medals)
                    }
                    .frame(maxHeight: 320)
                }
                .padding(14)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                if canUnlockSpecialChallenge {
                    Button(action: onUnlockSpecialChallenge) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Débloquer un défi spécial")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(colors: [Color.yellow.opacity(0.9), Color.orange.opacity(0.9)],
                                           startPoint: .leading,
                                           endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                    }
                } else {
                    Text("Débloquez 3 médailles 🏁 sur des défis de plus de 7 jours pour accéder au défi spécial.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
            .padding(20)
        }
    }
}

private struct SettingsMedalStatsCard: View {
    let totalMedals: Int
    let uniqueMedals: Int
    let completionCount: Int

    var body: some View {
        HStack(spacing: 12) {
            SettingsMedalStatItem(title: "Total", value: "\(totalMedals)")
            SettingsMedalStatItem(title: "Uniques", value: "\(uniqueMedals)")
            SettingsMedalStatItem(title: "🏁 >7j", value: "\(completionCount)")
        }
        .padding(14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SettingsMedalStatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}
