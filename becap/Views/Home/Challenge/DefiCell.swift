//
//  DefiCell.swift
//  becap
//
//  Created by Adam Mabrouki on 16/07/2025.
//

import SwiftUI

struct DefiCell: View {
    let challenge: Challenge
    let photos: [ChallengePhoto]
    let onDelete: () -> Void

    var body: some View {
        NavigationLink(destination: CalendarDetailView(challenge: challenge, photos: photos)) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.thinMaterial)
                    .shadow(color: Color.black.opacity(0.13), radius: 12, x: 0, y: 5)
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
        }
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

    // Renvoie uniquement les photos liées à ce challenge
    private var photosForChallenge: [ChallengePhoto] {
        photos.filter { $0.challengeId == challenge.id }
    }
}
