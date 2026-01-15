import SwiftUI

struct WaveCardShape: Shape {
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let height = rect.height
        let waveHeight = height * 0.12
        let baseHeight = height * 0.68

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: baseHeight))

        let width = rect.width
        for x in stride(from: width, through: 0, by: -4) {
            let relative = x / width
            let sine = sin(relative * .pi * 2 + phase)
            let y = baseHeight + waveHeight * sine
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        return path
    }
}
