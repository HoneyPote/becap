//
//  CoachProgramCardView.swift
//  becap
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//

import SwiftUI

struct CoachProgramCardView: View {
    let challenge: Challenge
    let isLocked: Bool
    let enrollment: ChallengeEnrollment?

    private var priceText: String {
        challenge.formattedPrice
    }

    private var joinedBadgeText: String {
        enrollment?.isPaid == true ? "Rejoint" : "En cours"
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            heroBackground

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    avatarView

                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.coachName ?? "Coach program")
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(challenge.shortTagline ?? "Programme personnalisé")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(challenge.title)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        if let duration = challenge.durationDays {
                            label(icon: "calendar", text: "\(duration) jours")
                        }
                        if let difficulty = challenge.difficultyLabel, !difficulty.isEmpty {
                            label(icon: "bolt.fill", text: difficulty)
                        }
                    }
                }

                Spacer(minLength: 12)

                HStack {
                    if isLocked {
                        label(icon: "lock.fill", text: priceText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule())
                    } else {
                        Text(joinedBadgeText.uppercased())
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }

                    Spacer()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 8)
    }

    private var heroBackground: some View {
        ZStack(alignment: .topLeading) {
            AsyncImage(url: URL(string: challenge.heroImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure(_):
                    Color.gray.opacity(0.2)
                        .overlay(
                            LinearGradient(colors: [.purple.opacity(0.6), .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                case .empty:
                    LinearGradient(colors: [.purple.opacity(0.4), .blue.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                @unknown default:
                    Color.gray
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            LinearGradient(colors: [Color.black.opacity(0.55), Color.black.opacity(0.2)], startPoint: .bottom, endPoint: .top)
        }
    }

    private var avatarView: some View {
        AsyncImage(url: URL(string: challenge.coachAvatarUrl ?? "")) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure(_), .empty:
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white.opacity(0.8))
            @unknown default:
                Color.white.opacity(0.3)
            }
        }
        .frame(width: 46, height: 46)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
        .shadow(radius: 4)
    }

    private func label(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.18))
        .clipShape(Capsule())
    }
}
