import SwiftUI

struct WaterHeaderView: View {
    let title: String
    let accessoryText: String
    let accessoryIcon: String
    let leadingAction: (() -> Void)?

    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            WaveCardShape(phase: phase)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)

            VStack {
                HStack {
                    if let leadingAction {
                        Button(action: leadingAction) {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)
                                .font(.system(size: 18, weight: .bold))
                                .frame(width: 34, height: 34)
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                        }
                    } else {
                        Image(systemName: "")
                            .foregroundColor(.black)
                            .font(.system(size: 18, weight: .bold))
                    }

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
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .kerning(0.6)
                    .foregroundColor(.black)
                    .padding(.bottom, 36)
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}
