import SwiftUI

struct WaterHeaderView: View {
    let title: String
    let accessoryText: String
    let accessoryIcon: String

    var body: some View {
        ZStack {
            AnimatedWaterView()

            VStack {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .bold))

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: accessoryIcon)
                        Text(accessoryText)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 28)
                .padding(.top, 36)

                Spacer()

                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
                    .padding(.bottom, 36)
            }
        }
    }
}
