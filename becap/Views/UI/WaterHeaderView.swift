import SwiftUI

struct WaterHeaderView: View {
    let title: String
    let accessoryText: String
    let accessoryIcon: String

    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            WaveCardShape(phase: phase)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)

            VStack {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.black)
                        .font(.system(size: 18, weight: .bold))

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: accessoryIcon)
                        Text(accessoryText)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    }
                    .foregroundColor(.black.opacity(0.75))
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)

                Spacer()

                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.bottom, 36)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}
