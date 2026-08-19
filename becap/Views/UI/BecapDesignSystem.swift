import SwiftUI

/// Shared visual foundations for the BeCap experience.
enum BecapColors {
    static let navy = Color(red: 0.035, green: 0.075, blue: 0.145)
    static let navyElevated = Color(red: 0.065, green: 0.125, blue: 0.215)
    static let electricBlue = Color(red: 0.20, green: 0.48, blue: 0.98)
    static let coral = Color(red: 1.00, green: 0.39, blue: 0.43)
    static let mint = Color(red: 0.31, green: 0.82, blue: 0.63)
    static let warning = Color(red: 0.98, green: 0.72, blue: 0.29)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let border = Color.white.opacity(0.14)

    static let brandGradient = LinearGradient(
        colors: [navyElevated, navy],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let actionGradient = LinearGradient(
        colors: [electricBlue, Color(red: 0.34, green: 0.30, blue: 0.93)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum BecapMetrics {
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let cardRadius: CGFloat = 22
    static let controlRadius: CGFloat = 16
    static let minimumTapTarget: CGFloat = 44
}

enum BecapTypography {
    static let display = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let title = Font.system(.title2, design: .rounded).weight(.bold)
    static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded).weight(.medium)
}

struct BecapBrandBackground: View {
    var body: some View {
        ZStack {
            BecapColors.brandGradient

            Circle()
                .fill(BecapColors.electricBlue.opacity(0.20))
                .frame(width: 330, height: 330)
                .blur(radius: 80)
                .offset(x: 150, y: -250)

            Circle()
                .fill(BecapColors.coral.opacity(0.10))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: -170, y: 330)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct BecapPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BecapTypography.headline)
            .foregroundStyle(BecapColors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(BecapColors.actionGradient)
            .clipShape(RoundedRectangle(cornerRadius: BecapMetrics.controlRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: BecapMetrics.controlRadius, style: .continuous)
                    .stroke(BecapColors.border, lineWidth: 1)
            }
            .shadow(color: BecapColors.electricBlue.opacity(0.24), radius: 12, y: 7)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.90 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct BecapFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, BecapMetrics.spacingM)
            .frame(minHeight: 52)
            .foregroundStyle(BecapColors.textPrimary)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: BecapMetrics.controlRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: BecapMetrics.controlRadius, style: .continuous)
                    .stroke(BecapColors.border, lineWidth: 1)
            }
    }
}

extension View {
    func becapFieldStyle() -> some View {
        modifier(BecapFieldStyle())
    }
}
