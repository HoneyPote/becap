import SwiftUI

struct WaveCardShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.68))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY * 0.72),
            control1: CGPoint(x: rect.maxX * 0.72, y: rect.maxY * 0.9),
            control2: CGPoint(x: rect.maxX * 0.28, y: rect.maxY * 0.5)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        return path
    }
}
