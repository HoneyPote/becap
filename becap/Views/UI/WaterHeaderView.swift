//
//  WaterHeaderView.swift
//  becap
//
//  Created by Victor Derveaux on 17/01/2025.
//

import SwiftUI

struct WaterHeaderView: View {
    let title: String

    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            WaveCardShape(phase: phase)
                .fill(
                    LinearGradient(colors: [Color.white, Color.white.opacity(0.94)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)

            VStack(spacing: .zero) {
                Spacer()

                Text("Bienvenue sur BeCap")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .kerning(0.6)
                    .foregroundColor(Color(red: 0.21, green: 0.32, blue: 0.50))
                    .padding(.bottom, 36)

                Spacer()

                Text(title)
                    .font(.system(size: 30, weight: .medium, design: .rounded))
                    .kerning(0.6)
                    .foregroundColor(.white)
                    .padding(.bottom, 24)
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
