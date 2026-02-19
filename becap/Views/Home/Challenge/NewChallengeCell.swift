//
//  NewChallengeCell.swift
//  becap
//
//  Created by Adam Mabrouki on 03/08/2025.
//

import SwiftUI

struct NewChallengeCell: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.76, blue: 0.88),
                                Color(red: 0.97, green: 0.61, blue: 0.77)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.30), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 7)

                VStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(radius: 1, x: 0, y: 3)

                    Text("Nouveau défi")
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
            }
            .frame(height: 100)
            .contentShape(RoundedRectangle(cornerRadius: 24))

        }
        .buttonStyle(PlainButtonStyle())
        .padding(4)
    }
}
