//
//  LockedChallengeCell.swift
//  becap
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//

import SwiftUI
import AVKit

struct LockedChallengeCell: View {
    let challenge: Challenge
    let onUnlock: () -> Void

    @State private var showInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Défi verrouillé", systemImage: "lock.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: { showInfo.toggle() }) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.white)
                        .imageScale(.large)
                }
                .popover(isPresented: $showInfo) {
                    ChallengeInfoBubble(challenge: challenge)
                        .frame(width: 240)
                        .padding()
                }
            }

            Text(challenge.title)
                .font(.title3.bold())
                .foregroundColor(.white)
                .lineLimit(2)

            Text(challenge.formattedPrice)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            HStack {
                Text("Déverrouiller le défi")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.12))
            .cornerRadius(12)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.gray.opacity(0.6), Color.black.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "lock.fill")
                .foregroundColor(.white.opacity(0.7))
                .padding(12)
        }
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 8)
        .onTapGesture { onUnlock() }
    }
}
