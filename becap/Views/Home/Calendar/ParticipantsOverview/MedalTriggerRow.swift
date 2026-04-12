//
//  MedalTriggerRow.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//

import SwiftUI
import AVFoundation
import UIKit

struct MedalTriggerRow: View {
    let medalCount: Int
    let participantName: String
    let progress: ParticipantProgress?
    let challenge: (any ChallengeRepresentable)?
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
    var challenge: (any ChallengeRepresentable)? = nil

    @State private var player: AVAudioPlayer?

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
                                    earnedMedals: medals,
                                    animateProgress: true)
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Color(red: 20/255, green: 52/255, blue: 96/255),
                                    Color(red: 80/255, green: 40/255, blue: 124/255),
                                    Color(red: 36/255, green: 118/255, blue: 170/255)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)
        .onAppear {
            guard hasNewMedal else { return }
            playCelebrationSound()
            vibrate()
        }
    }

    private var hasNewMedal: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return medals.contains { Calendar.current.isDate($0.achievedDate, inSameDayAs: today) }
    }

    private func playCelebrationSound() {
        guard let url = Bundle.main.url(forResource: "success", withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("❌ Erreur son: \(error.localizedDescription)")
        }
    }

    private func vibrate() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct MedalProgressCard: View {
    let progress: ParticipantProgress
    let challenge: any ChallengeRepresentable

    private var nextMedal: MedalDefinition? {
        MedalCatalog.nextStreakDefinition(for: progress, challenge: challenge)
    }

    @State private var animatedProgress: Double = 0

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

                    ProgressView(value: animatedProgress, total: Double(target))
                        .tint(.yellow)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.6)) {
                                animatedProgress = Double(progress.currentStreak)
                            }
                        }

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
    var animateProgress: Bool = false

    @State private var animatedIndex: Int = -1
    @State private var pulse = false

    private var earnedNames: Set<String> {
        Set(earnedMedals.map(\.name))
    }

    private var lastUnlockedIndex: Int {
        let indices = definitions.enumerated().compactMap { index, definition in
            earnedNames.contains(definition.name) ? index : nil
        }
        return indices.max() ?? -1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Collection")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 12) {
                ForEach(Array(definitions.enumerated()), id: \.element.id) { index, definition in
                    let unlocked = earnedNames.contains(definition.name)
                    let isLatestUnlocked = unlocked && index == lastUnlockedIndex
                    VStack(spacing: 6) {
                        ZStack {
                            if isLatestUnlocked {
                                Circle()
                                    .fill(definition.tier.tintColor.opacity(0.25))
                                    .frame(width: 46, height: 46)
                                    .scaleEffect(pulse ? 1.2 : 0.95)
                                    .opacity(pulse ? 0.2 : 0.6)
                                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)

                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                    .offset(x: 12, y: -14)
                                    .opacity(pulse ? 0.2 : 1)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
                            }

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
                        }

                        Text(definition.name)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.white.opacity(unlocked ? 0.8 : 0.4))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(animateProgress && index <= lastUnlockedIndex ? (index <= animatedIndex ? 1 : 0) : 1)
                    .scaleEffect(animateProgress && index <= lastUnlockedIndex ? (index <= animatedIndex ? 1 : 0.8) : 1)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            guard animateProgress, lastUnlockedIndex >= 0 else {
                animatedIndex = lastUnlockedIndex
                return
            }

            animatedIndex = -1
            pulse = true
            for index in 0...lastUnlockedIndex {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.12) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        animatedIndex = index
                    }
                }
            }
        }
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
