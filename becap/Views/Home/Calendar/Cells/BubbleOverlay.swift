//
//  BubbleOverlay.swift
//  becap
//
//  Created by Adam Mabrouki on 04/09/2025.
//

import SwiftUI
// MARK: - Bubble overlay + inline grid
 struct BubbleOverlay<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Triangle()
                .fill(.ultraThinMaterial)
                .frame(width: 18, height: 10)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .offset(y: 8)

            VStack { content }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.7)
                )
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8) // lighter shadow
                .frame(maxWidth: 600)
        }
        .padding(.horizontal, 16)
    }
}

 struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
