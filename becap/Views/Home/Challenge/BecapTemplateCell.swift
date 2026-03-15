//
//  BecapTemplateCell.swift
//  becap
//
//  Created by Victor Derveaux on 03/03/2026.
//

import SwiftUI

struct BecapTemplateCell: View {
    let template: BecapChallengeTemplate

    private var gradientColors: [Color] {
        switch template.type {
        case .plank: return [Color(hex: "#F59E0B"), Color(hex: "#EF4444")]
        case .reading: return [Color(hex: "#22C55E"), Color(hex: "#0EA5E9")]
        case .food: return [Color(hex: "#F97316"), Color(hex: "#EC4899")]
        }
    }

    private var iconName: String {
        switch template.type {
        case .plank: return "figure.strengthtraining.traditional"
        case .reading: return "book.fill"
        case .food: return "fork.knife"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
            }

            Spacer()

            Text(template.title)
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .multilineTextAlignment(.leading)
                .foregroundColor(.white)
                .lineLimit(2)

            Text("Défi Becap")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(14)
        .frame(height: 170)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradientColors.map { $0.opacity(0.92) },
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
