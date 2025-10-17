//
//  PremiumChallengeCell.swift
//  becap
//
//  Created by OpenAI on 2025-02-14.
//

import SwiftUI

struct PremiumChallengeCell: View {
    let challenge: PremiumChallenge
    let onUnlockTapped: () -> Void
    let onInfoTapped: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: challenge.isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                    .font(.title3.bold())
                    .foregroundStyle(challenge.isUnlocked ? Color.green : Color.white.opacity(0.85))
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.08)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Text(challenge.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)

                Button(action: onInfoTapped) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(Color.white.opacity(0.9))
                        .padding(6)
                }
                .accessibilityLabel("Plus d'informations sur le défi premium")
            }

            if challenge.isUnlocked {
                Label("Défi débloqué", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    Text(String(format: "%.2f %@", NSDecimalNumber(decimal: challenge.price).doubleValue, challenge.currencyCode))
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)

                    Button(action: onUnlockTapped) {
                        HStack {
                            Image(systemName: "lock.open")
                            Text("Déverrouiller")
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.white.opacity(0.85))
                    .foregroundColor(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(challenge.isUnlocked ? Color(red: 0.25, green: 0.41, blue: 0.74) : Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(challenge.isUnlocked ? 0.0 : 0.35))
        )
        .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 8)
    }
}

struct PremiumChallengeCell_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(colors: [.black, .blue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                PremiumChallengeCell(
                    challenge: PremiumChallenge.sampleData.first!,
                    onUnlockTapped: {},
                    onInfoTapped: {}
                )

                PremiumChallengeCell(
                    challenge: PremiumChallenge.sampleData.first!.withUnlocked(),
                    onUnlockTapped: {},
                    onInfoTapped: {}
                )
            }
            .padding()
        }
    }
}

private extension PremiumChallenge {
    func withUnlocked() -> PremiumChallenge {
        var copy = self
        copy.isUnlocked = true
        return copy
    }
}
