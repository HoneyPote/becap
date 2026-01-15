import SwiftUI

struct AnimatedWaterView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.35, green: 0.84, blue: 0.9),
                        Color(red: 0.18, green: 0.5, blue: 0.62),
                        Color(red: 0.12, green: 0.28, blue: 0.36)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                WaveShape(
                    phase: phase,
                    amplitude: proxy.size.height * 0.09,
                    baseline: proxy.size.height * 0.62
                )
                .fill(Color.white.opacity(0.35))

                WaveShape(
                    phase: phase + .pi / 2,
                    amplitude: proxy.size.height * 0.06,
                    baseline: proxy.size.height * 0.68
                )
                .fill(Color.white.opacity(0.22))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

private struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var baseline: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: 0, y: height))
        for x in stride(from: 0, through: width, by: 4) {
            let relative = x / width
            let sine = sin(relative * .pi * 2 + phase)
            let y = baseline + amplitude * sine
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()

        return path
    }
}
