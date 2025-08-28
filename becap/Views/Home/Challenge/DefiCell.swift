//
//  DefiCell.swift
//  becap
//
//  Created by Adam Mabrouki on 16/07/2025.
//

import SwiftUI

struct DefiCell: View {
    let challenge: Challenge
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.98, green: 0.80, blue: 0.36))
                .shadow(radius: 5, x: 0, y: 5)

            VStack(spacing: 8) {
                Text(challenge.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text("\(challenge.participantUids.count) participant(s)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
        }
        .frame(height: 100)
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
        .padding(4)
    }
}
