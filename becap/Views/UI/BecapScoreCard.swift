import SwiftUI

/// Présentation commune du score multimodal, utilisée à la publication et dans le fil.
struct BecapScoreCard: View {
    let score: MultimodalScore
    var compact = false

    private var progress: Double {
        Double(score.score) / 10
    }

    private var accent: Color {
        switch score.score {
        case 8...10: return Color(red: 0.43, green: 0.91, blue: 0.73)
        case 5...7: return Color(red: 0.98, green: 0.78, blue: 0.35)
        default: return Color(red: 0.96, green: 0.49, blue: 0.48)
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: compact ? 14 : 18) {
            scoreGauge

            VStack(alignment: .leading, spacing: compact ? 7 : 10) {
                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(accent)
                    Text("BECAP SCORE")
                        .font(.system(.caption, design: .rounded).weight(.heavy))
                        .tracking(1.1)
                        .foregroundStyle(.white.opacity(0.72))
                }

                if !score.feedback.isEmpty {
                    Text(score.feedback)
                        .font(.system(compact ? .subheadline : .body, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(compact ? 2 : 3)
                }

                if !compact, !score.detectedElements.isEmpty {
                    detectedElements
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(compact ? 14 : 18)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.13), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Becap Score : \(score.score) sur 10. \(score.feedback)")
    }

    private var scoreGauge: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: compact ? 5 : 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(accent,
                        style: StrokeStyle(lineWidth: compact ? 5 : 6,
                                           lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: -2) {
                Text("\(score.score)")
                    .font(.system(size: compact ? 23 : 29, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Text("/ 10")
                    .font(.system(size: compact ? 9 : 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .foregroundStyle(.white)
        }
        .frame(width: compact ? 62 : 76, height: compact ? 62 : 76)
    }

    private var detectedElements: some View {
        Text(score.detectedElements.prefix(4).joined(separator: "  •  "))
            .font(.system(.caption2, design: .rounded).weight(.bold))
            .foregroundStyle(.white.opacity(0.58))
            .lineLimit(1)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.18).opacity(0.96),
                    Color(red: 0.12, green: 0.20, blue: 0.25).opacity(0.92)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(accent.opacity(0.16))
                    .frame(width: 110, height: 110)
                    .blur(radius: 28)
                    .offset(x: 28, y: -40)
            }
    }
}
