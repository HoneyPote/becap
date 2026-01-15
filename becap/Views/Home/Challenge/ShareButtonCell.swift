//
//  ShareButtonCell.swift
//  becap
//
//  Created by Adam Mabrouki on 18/07/2025.
//

import SwiftUI

struct ShareButtonCell: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.29, green: 0.58, blue: 0.84), // Bleu clair
                                Color(red: 0.21, green: 0.44, blue: 0.69)  // Bleu foncé
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 5)
                VStack(spacing: 8) {
                    Image("network")
                           .resizable()
                           .scaledToFit()
                           .frame(width: 28, height: 28)
                           .foregroundColor(.white)
                           .shadow(radius: 1, x: 0, y: 3)

                    Text("Partager un défi")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
            }
            .frame(height: 100)
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
//        .buttonStyle(.hapticPlain)
        .padding(4)
    }
}
