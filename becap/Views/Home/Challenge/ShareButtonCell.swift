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
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.80, green: 0.88, blue: 1.00),
                                Color(red: 0.64, green: 0.76, blue: 0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.30), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 7)

                VStack(spacing: 10) {
                    Image("network")
                           .resizable()
                           .scaledToFit()
                           .frame(width: 34, height: 34)
                           .foregroundColor(.white)
                           .shadow(radius: 1, x: 0, y: 3)

                    Text("Partager un défi")
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
