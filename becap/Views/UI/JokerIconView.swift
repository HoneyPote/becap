//
//  JokerIconView.swift
//  becap
//
//  Created by OpenAI on 07/08/2025.
//

import SwiftUI

struct JokerIconView: View {
    var size: CGFloat
    var fillColor: Color
    var isDimmed: Bool

    init(size: CGFloat = 28, fillColor: Color = .white, isDimmed: Bool = false) {
        self.size = size
        self.fillColor = fillColor
        self.isDimmed = isDimmed
    }

    var body: some View {
        let backgroundOpacity = isDimmed ? 0.18 : 0.82
        let borderOpacity = isDimmed ? 0.25 : 0.95
        let borderWidth = max(1, size * 0.08)

        return ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(fillColor.opacity(backgroundOpacity))

            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(fillColor.opacity(borderOpacity), lineWidth: borderWidth)

            Image("joker1png")
                .resizable()
                .renderingMode(.original)
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size * 0.62, height: size * 0.62)
                .shadow(color: .black.opacity(isDimmed ? 0.0 : 0.25),
                        radius: size * 0.12,
                        x: 0,
                        y: size * 0.08)
        }
        .frame(width: size, height: size)
        .opacity(isDimmed ? 0.5 : 1.0)
        .accessibilityElement()
        .accessibilityLabel(isDimmed ? "Joker utilisé" : "Joker disponible")
    }
}

struct JokerIconView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            JokerIconView()
                .previewDisplayName("Actif")
            JokerIconView(isDimmed: true)
                .previewDisplayName("Utilisé")
            JokerIconView(size: 48, fillColor: .yellow)
                .previewDisplayName("Grand format")
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
