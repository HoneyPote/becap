//
//  DefiCell.swift
//  becap
//
//  Created by Adam Mabrouki on 16/07/2025.
//

import SwiftUI

struct DefiCell: View {
    let challenge: Challenge
    let onQuit: () -> Void
    let onReport: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.97, blue: 0.98),
                            Color(red: 0.93, green: 0.94, blue: 0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 5)
                .opacity(0.96)

            challengeBackgroundIllustration
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .allowsHitTesting(false)

            VStack(spacing: 8) {
                Text(challenge.title)
                    .font(.headline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text("\(challenge.participantUids.count) participant(s)")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack {
                    Text(challenge.status.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .background(challenge.status == .active
                            ? Color(red: 0.55, green: 0.82, blue: 0.61)
                            : Color(red: 1.0, green: 0.71, blue: 0.81))
                .cornerRadius(10)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 40)
            .background(Color.white.opacity(0.34).blur(radius: 1.2))
        }
        .frame(height: 100) // garde la taille initiale des cellules
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                onQuit()
            } label: {
                Label("Quitter le défi", systemImage: "trash")
            }

            Button {
                onReport()
            } label: {
                Label("Signaler", systemImage: "exclamationmark.bubble")
            }
        }
        .padding(4)
    }

    private var challengeBackgroundIllustration: some View {
        ZStack {
            Image(systemName: challenge.challengeCellFallbackSymbolName)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(.black.opacity(0.13))

            if !challenge.challengeCellBackgroundAssetName.isEmpty {
                Image(challenge.challengeCellBackgroundAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(0.32)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

private extension Challenge {
    /// Assets illustratifs dédiés aux cartes Home (100pt de haut).
    /// Noms prévus pour les visuels demandés:
    /// - sport: `challenge_bg_sport`
    /// - dessin: `challenge_bg_drawing`
    /// - nourriture: `challenge_bg_food`
    /// - lecture: `challenge_bg_reading`
    /// - autre/course: fallback symbole
    var challengeCellBackgroundAssetName: String {
        switch category {
        case .sport:
            return "challenge_bg_sport"
        case .dessin:
            return "challenge_bg_drawing"
        case .nourriture:
            return "challenge_bg_food"
        case .lecture:
            return "challenge_bg_reading"
        default:
            return ""
        }
    }

    var challengeCellFallbackSymbolName: String {
        switch category {
        case .sport: return "dumbbell.fill"
        case .dessin: return "pencil.and.outline"
        case .nourriture: return "fork.knife"
        case .lecture: return "book.closed.fill"
        case .course: return "figure.run"
        case .autre, .none: return "sparkles"
        }
    }
}
