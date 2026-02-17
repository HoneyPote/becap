//
//  DefiCell.swift
//  becap
//
//  Created by Adam Mabrouki on 16/07/2025.
//

import SwiftUI

struct DefiCell: View {
    let challenge: Challenge
    let onQuit: () -> Void
    let onReport: () -> Void

    private var participantsCount: Int {
        challenge.participantUids.count
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            cardBackground

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(challenge.title)
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 8)

                    statusBadge
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.95))

                    Text("\(participantsCount) participant\(participantsCount > 1 ? "s" : "")")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.95))

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.black.opacity(0.22), in: Capsule())
            }
            .padding(12)
        }
        .frame(height: 125)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                onQuit()
            } label: {
                Label("Quitter le défi", systemImage: "trash")
            }

            Button {
                onReport()
            } label: {
                Label("Signaler", systemImage: "exclamationmark.bubble")
            }
        }
        .padding(4)
    }

    private var cardBackground: some View {
        ZStack {
            Image(challenge.calendarBackgroundImageName)
                .resizable()
                .scaledToFill()

            LinearGradient(
                colors: [
                    .black.opacity(0.20),
                    .black.opacity(0.45)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.24), radius: 8, x: 0, y: 5)
    }

    private var statusBadge: some View {
        Text(challenge.status.rawValue)
            .font(.system(.caption, design: .rounded).weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                challenge.status == .active
                ? Color(red: 0.25, green: 0.77, blue: 0.48)
                : Color(red: 0.61, green: 0.65, blue: 0.75)
            )
            .clipShape(Capsule())
    }
}
