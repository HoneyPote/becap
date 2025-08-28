//
//  GlassCard.swift
//  becap
//
//  Created by Adam Mabrouki on 03/08/2025.
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
                .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 5)
            content
                .padding(20)
        }
    }
}

struct GlassCircleIcon: View {
    let systemName: String

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.19), lineWidth: 0.7)
                )
                .shadow(color: Color.black.opacity(0.19), radius: 5, x: 0, y: 7)

            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat = 0
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 10 * sin(animatableData * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, (int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = ((int >> 24) & 0xff, (int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Array {
    func unique<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
