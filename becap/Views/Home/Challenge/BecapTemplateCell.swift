//
//  BecapTemplateCell.swift
//  becap
//
//  Created by Victor Derveaux on 03/03/2026.
//

import SwiftUI

struct BecapTemplateCell: View {
    let template: BecapChallengeTemplate

    var body: some View {
        VStack(spacing: 12) {

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)

            Text(template.title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)

            Text("Créer un défi")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.8))

            Spacer()
        }
        .frame(height: 170)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.85),
                            Color.blue.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
    }
}
