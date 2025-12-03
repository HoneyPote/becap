//
//  LockedChallengeCell.swift
//  becap
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//

import SwiftUI
import AVKit
import UIKit

struct LockedChallengeCell: View {
    let challenge: Challenge
    let onUnlock: () -> Void

    @State private var showInfo = false
    @State private var shakeAngle: Double = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color(red: 0.12, green: 0.13, blue: 0.16), Color(red: 0.05, green: 0.05, blue: 0.07)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 12)

            VStack(alignment: .center, spacing: 16) {
                HStack {
                    Spacer()
                    Button(action: { showInfo.toggle() }) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color.white.opacity(0.85))
                            .imageScale(.large)
                            .padding(10)
                            .background(Color.white.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showInfo) {
                        ChallengeInfoBubble(challenge: challenge)
                            .frame(width: 240)
                            .padding()
                    }
                }

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: Color.white.opacity(0.18), radius: 12, x: -6, y: -6)
                        .shadow(color: Color.black.opacity(0.5), radius: 18, x: 10, y: 10)

                    Image(systemName: "lock.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(LinearGradient(colors: [Color.white, Color.white.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        .rotationEffect(.degrees(shakeAngle))
                }
                .frame(width: 90, height: 90)

                VStack(spacing: 6) {
                    Text(challenge.title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Text(challenge.formattedPrice)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(Color.white.opacity(0.8))
                }
                .padding(.horizontal, 12)

                Text("Touchez pour déverrouiller")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08), in: Capsule())
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 220)
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .padding(4)
        .onTapGesture {
            triggerLockedFeedback()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                onUnlock()
            }
        }
    }
}

private extension LockedChallengeCell {
    func triggerLockedFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.15, dampingFraction: 0.2, blendDuration: 0.2)) {
            shakeAngle = -10
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.32, blendDuration: 0.2)) {
                shakeAngle = 10
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.45, blendDuration: 0.2)) {
                shakeAngle = 0
            }
        }
    }
}
