import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            BecapBrandBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    VStack(spacing: BecapMetrics.spacingM) {
                        Image(systemName: "flag.checkered.circle.fill")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundStyle(BecapColors.mint)
                            .accessibilityHidden(true)

                        Text("Passe à l’action,\nensemble.")
                            .font(BecapTypography.display)
                            .foregroundStyle(BecapColors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("BeCap transforme tes objectifs en défis quotidiens à partager avec tes proches.")
                            .font(BecapTypography.body)
                            .foregroundStyle(BecapColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: BecapMetrics.spacingM) {
                        welcomeBenefit(icon: "target", title: "Un objectif clair",
                                       message: "Avance un jour après l’autre grâce à une progression visible.")
                        welcomeBenefit(icon: "camera.fill", title: "Une preuve authentique",
                                       message: "Partage une photo ou une vidéo pour valider ta journée.")
                        welcomeBenefit(icon: "person.3.fill", title: "La force du groupe",
                                       message: "Encourage tes amis et reste motivé jusqu’au bout.")
                    }

                    Button("Commencer", action: onContinue)
                        .buttonStyle(BecapPrimaryButtonStyle())
                        .accessibilityHint("Accède à la création ou à la connexion au compte")
                }
                .padding(.horizontal, BecapMetrics.spacingL)
                .padding(.vertical, 40)
            }
        }
    }

    private func welcomeBenefit(icon: String, title: String, message: String) -> some View {
        HStack(spacing: BecapMetrics.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(BecapColors.mint)
                .frame(width: 46, height: 46)
                .background(BecapColors.mint.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: BecapMetrics.spacingXS) {
                Text(title)
                    .font(BecapTypography.headline)
                    .foregroundStyle(BecapColors.textPrimary)
                Text(message)
                    .font(BecapTypography.body)
                    .foregroundStyle(BecapColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(BecapMetrics.spacingM)
        .background(.thinMaterial,
                    in: RoundedRectangle(cornerRadius: BecapMetrics.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
