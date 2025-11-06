//
//  JokerIconView.swift
//  becap
//
//  Created by OpenAI on 07/08/2025.
//

import SwiftUI

struct JokerIconView: View {
    var size: CGFloat
    var accentColor: Color
    var isDimmed: Bool

    init(size: CGFloat = 28, accentColor: Color = Color(red: 0.98, green: 0.36, blue: 0.62), isDimmed: Bool = false) {
        self.size = size
        self.accentColor = accentColor
        self.isDimmed = isDimmed
    }

    var body: some View {
        let baseGradient = LinearGradient(colors: backgroundColors,
                                          startPoint: .topLeading,
                                          endPoint: .bottomTrailing)
        let highlightGradient = LinearGradient(colors: highlightColors,
                                               startPoint: .top,
                                               endPoint: .bottom)

        return ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(baseGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                        .stroke(Color.white.opacity(isDimmed ? 0.25 : 0.55), lineWidth: size * 0.06)
                )
                .shadow(color: Color.black.opacity(isDimmed ? 0.0 : 0.28),
                        radius: size * 0.22,
                        x: 0,
                        y: size * 0.12)

            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(Color.white.opacity(isDimmed ? 0.16 : 0.3))
                .frame(width: size * 0.74, height: size * 0.78)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(Color.white.opacity(isDimmed ? 0.16 : 0.35), lineWidth: size * 0.04)
                )

            JokerGlyph(size: size,
                       accentGradient: highlightGradient,
                       sparkleColor: accentColor.opacity(isDimmed ? 0.55 : 0.9),
                       isDimmed: isDimmed)
                .frame(width: size * 0.68, height: size * 0.72)
        }
        .frame(width: size, height: size)
        .opacity(isDimmed ? 0.55 : 1.0)
        .accessibilityElement()
        .accessibilityLabel(isDimmed ? "Joker utilisé" : "Joker disponible")
    }

    private var backgroundColors: [Color] {
        if isDimmed {
            return [
                Color(red: 0.20, green: 0.24, blue: 0.36).opacity(0.75),
                Color(red: 0.09, green: 0.10, blue: 0.18).opacity(0.85)
            ]
        }

        return [
            Color(red: 0.50, green: 0.32, blue: 0.96),
            Color(red: 0.15, green: 0.21, blue: 0.53)
        ]
    }

    private var highlightColors: [Color] {
        if isDimmed {
            return [
                accentColor.opacity(0.45),
                accentColor.opacity(0.2)
            ]
        }

        return [
            accentColor.opacity(0.95),
            accentColor.opacity(0.55)
        ]
    }
}

private struct JokerGlyph: View {
    let size: CGFloat
    let accentGradient: LinearGradient
    let sparkleColor: Color
    let isDimmed: Bool

    var body: some View {
        ZStack {
            topHat
            face
            sparkle
        }
    }

    private var topHat: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                .fill(accentGradient)
                .frame(width: size * 0.58, height: size * 0.26)
                .offset(y: -size * 0.22)

            Capsule()
                .fill(accentGradient)
                .frame(width: size * 0.72, height: size * 0.12)
                .offset(y: -size * 0.04)
                .shadow(color: Color.black.opacity(isDimmed ? 0.0 : 0.25), radius: size * 0.08, x: 0, y: size * 0.04)
        }
    }

    private var face: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(Color.white.opacity(isDimmed ? 0.35 : 0.55))
                .frame(width: size * 0.52, height: size * 0.52)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(Color.white.opacity(isDimmed ? 0.15 : 0.4), lineWidth: size * 0.03)
                )

            VStack(spacing: size * 0.08) {
                HStack(spacing: size * 0.14) {
                    eye
                    eye
                }

                smile
            }
        }
        .offset(y: size * 0.12)
    }

    private var eye: some View {
        Circle()
            .fill(Color.black.opacity(isDimmed ? 0.25 : 0.75))
            .frame(width: size * 0.1, height: size * 0.1)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(isDimmed ? 0.15 : 0.5))
                    .frame(width: size * 0.04)
                    .offset(x: size * 0.02, y: -size * 0.02)
            )
    }

    private var smile: some View {
        Capsule()
            .fill(Color.black.opacity(isDimmed ? 0.25 : 0.7))
            .frame(width: size * 0.36, height: size * 0.12)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isDimmed ? 0.08 : 0.35), lineWidth: size * 0.015)
            )
    }

    private var sparkle: some View {
        Image(systemName: "sparkles")
            .font(.system(size: size * 0.22, weight: .semibold, design: .rounded))
            .foregroundColor(sparkleColor)
            .offset(x: size * 0.22, y: -size * 0.42)
            .shadow(color: sparkleColor.opacity(isDimmed ? 0.2 : 0.5), radius: size * 0.08)
    }
}

struct JokerIconView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            JokerIconView()
                .previewDisplayName("Actif")
            JokerIconView(isDimmed: true)
                .previewDisplayName("Utilisé")
            JokerIconView(size: 48, accentColor: .orange)
                .previewDisplayName("Grand format")
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
