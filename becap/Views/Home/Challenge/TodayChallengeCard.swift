import SwiftUI

struct TodayChallengeCard: View {
    let challenge: Challenge

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

    private var remainingText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: challenge.lastDayDate, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BecapMetrics.spacingM) {
            HStack {
                Label("AUJOURD’HUI", systemImage: "sparkles")
                    .font(BecapTypography.caption.weight(.bold))
                    .foregroundStyle(BecapColors.mint)

                Spacer()

                Text("Jour \(currentDay)/\(challenge.duration)")
                    .font(BecapTypography.caption)
                    .foregroundStyle(BecapColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: BecapMetrics.spacingS) {
                Text(challenge.title)
                    .font(BecapTypography.title)
                    .foregroundStyle(BecapColors.textPrimary)
                    .lineLimit(2)

                Text("Continue sur ta lancée et partage ta preuve du jour avec le groupe.")
                    .font(BecapTypography.body)
                    .foregroundStyle(BecapColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: BecapMetrics.spacingS) {
                ProgressView(value: progress)
                    .tint(BecapColors.mint)

                HStack {
                    Label("\(challenge.participantUids.count) participant\(challenge.participantUids.count > 1 ? "s" : "")",
                          systemImage: "person.2.fill")
                    Spacer()
                    Text("Fin \(remainingText)")
                }
                .font(BecapTypography.caption)
                .foregroundStyle(BecapColors.textSecondary)
            }

            HStack(spacing: BecapMetrics.spacingS) {
                Image(systemName: "camera.fill")
                Text("Publier ma preuve")
                Spacer()
                Image(systemName: "arrow.right")
            }
            .font(BecapTypography.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, BecapMetrics.spacingM)
            .frame(minHeight: 52)
            .background(BecapColors.actionGradient)
            .clipShape(RoundedRectangle(cornerRadius: BecapMetrics.controlRadius, style: .continuous))
        }
        .padding(BecapMetrics.spacingL)
        .background {
            RoundedRectangle(cornerRadius: BecapMetrics.cardRadius, style: .continuous)
                .fill(BecapColors.navyElevated.opacity(0.92))
        }
        .overlay {
            RoundedRectangle(cornerRadius: BecapMetrics.cardRadius, style: .continuous)
                .stroke(BecapColors.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 20, y: 12)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Ouvre le défi pour publier ta preuve du jour")
    }
}

struct NoActiveChallengeCard: View {
    let createAction: () -> Void

    var body: some View {
        VStack(spacing: BecapMetrics.spacingM) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(BecapColors.mint)

            VStack(spacing: BecapMetrics.spacingS) {
                Text("Prêt pour un nouveau défi ?")
                    .font(BecapTypography.title)
                    .foregroundStyle(BecapColors.textPrimary)
                Text("Crée ton prochain objectif et invite tes amis à te rejoindre.")
                    .font(BecapTypography.body)
                    .foregroundStyle(BecapColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button("Créer un défi", action: createAction)
                .buttonStyle(BecapPrimaryButtonStyle())
        }
        .padding(BecapMetrics.spacingL)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: BecapMetrics.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BecapMetrics.cardRadius, style: .continuous)
                .stroke(BecapColors.border, lineWidth: 1)
        }
    }
}
