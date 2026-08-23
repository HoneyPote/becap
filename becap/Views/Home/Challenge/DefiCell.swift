//
//  DefiCell.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI

struct DefiCell: View {
    let challenge: Challenge
    let onReport: () -> Void
    let onRestart: (() -> Void)?
    let isRestarting: Bool

    init(challenge: Challenge,
         onReport: @escaping () -> Void,
         onRestart: (() -> Void)? = nil,
         isRestarting: Bool = false) {
        self.challenge = challenge
        self.onReport = onReport
        self.onRestart = onRestart
        self.isRestarting = isRestarting
    }

    private let corner: CGFloat = BecapMetrics.cardRadius

    private var participantsCount: Int { challenge.participantUids.count }

    private var currentDay: Int {
        let elapsedDays = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: challenge.startDate),
            to: Calendar.current.startOfDay(for: Date())
        ).day ?? 0
        return min(max(elapsedDays + 1, 1), max(challenge.duration, 1))
    }

    private var progress: Double {
        Double(currentDay) / Double(max(challenge.duration, 1))
    }

    private var challengeArtworkName: String {
        switch challenge.category {
        case .sport: return "sportDefiCell"
        case .drawing: return "drawDefiCell"
        case .food: return "foodDefiCell"
        case .reading: return "BookDefiCell"
        case .running: return "iphone_wallpaper_duo_run"
        case .other, .none: return "sunset"
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)

        ZStack(alignment: .bottomLeading) {
            Image(challengeArtworkName)
                .resizable()
                .scaledToFill()
                .accessibilityHidden(true)

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.16), location: 0),
                    .init(color: .black.opacity(0.42), location: 0.48),
                    .init(color: .black.opacity(0.78), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .accessibilityHidden(true)

            // ✅ Content
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(challenge.title)
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 8)

                    statusBadge
                }

                Spacer(minLength: 0)

                if challenge.status == .active {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Jour \(currentDay) sur \(challenge.duration)")
                            .font(BecapTypography.caption)
                            .foregroundStyle(.white)

                        ProgressView(value: progress)
                            .tint(BecapColors.mint)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.95))

                    Text("\(participantsCount) participant\(participantsCount > 1 ? "s" : "")")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.95))

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.22), in: Capsule())
            }
            .padding(10)

            if challenge.status == .finished, let onRestart {
                restartButton(action: onRestart)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(12)
            }
        }
        .frame(height: 170)
        .clipShape(shape) 
        .overlay(
            shape.stroke(.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.24), radius: 8, x: 0, y: 5)
        .contentShape(shape) // ✅ hitbox arrondie
        .contextMenu {
            Button { onReport() } label: {
                Label("Signaler", systemImage: "exclamationmark.bubble")
            }
        }
        .padding(4)
        .buttonStyle(.plain)
    }

    private func restartButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isRestarting {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                }

                Text("Recommencer")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.black.opacity(0.55), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        }
        .disabled(isRestarting)
        .buttonStyle(.plain)
    }

    private var statusBadge: some View {
        Text(challenge.status.rawValue)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                challenge.status == .active
                ? BecapColors.mint
                : BecapColors.textSecondary
            )
            .clipShape(Capsule())
    }
}
