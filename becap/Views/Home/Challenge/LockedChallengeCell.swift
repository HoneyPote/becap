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
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color.gray.opacity(0.65), Color.black.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    HStack {
                        Text("Défi verrouillé")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }

                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.85))

                    HStack {
                        Spacer()
                        Button(action: { showInfo.toggle() }) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.white)
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showInfo) {
                            ChallengeInfoBubble(challenge: challenge)
                                .frame(width: 240)
                                .padding()
                        }
                    }
                }

                Text(challenge.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(challenge.formattedPrice)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))

                Button(action: onUnlock) {
                    HStack {
                        Text("Déverrouiller le défi")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100)
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .padding(4)
    }
}
