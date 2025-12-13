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
    var isLocked: Bool = false
    var onLockedTap: (() -> Void)?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.97, blue: 0.98), // #F7F8FA
                            Color(red: 0.93, green: 0.94, blue: 0.95)  // #ECEEF1
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 5)
                .opacity(0.96)

            VStack(spacing: 8) {
                Text(challenge.title)
                    .font(.headline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text("\(challenge.participantUids.count) participant(s)")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack {
                    Text(challenge.status.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .background(challenge.status == .active
                            ? Color(red: 0.55, green: 0.82, blue: 0.61)
                            : Color(red: 1.0, green: 0.71, blue: 0.81))
                .cornerRadius(10)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 40)
        }
        .frame(height: 100)
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            if !isLocked {
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
        .overlay {
            if isLocked {
                Color.clear
                    .contentShape(RoundedRectangle(cornerRadius: 18))
                    .onTapGesture { onLockedTap?() }
            }
        }
    }
}
