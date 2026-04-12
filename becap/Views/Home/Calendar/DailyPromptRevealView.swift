//
//  DailyPromptRevealView.swift
//  becap
//
//  Created by Codex on 17/02/2026.
//

import SwiftUI
import UIKit

struct DailyPromptRevealView: View {
    let word: String
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showButton = false
    @State private var shouldPulseGlow = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.72))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Mot du jour")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white.opacity(0.82))
                    .tracking(0.4)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(colors: [Color.yellow.opacity(0.30), .clear],
                                           center: .center,
                                           startRadius: 12,
                                           endRadius: 130)
                        )
                        .frame(width: 260, height: 260)
                        .scaleEffect(shouldPulseGlow ? 1.08 : 0.94)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                                   value: shouldPulseGlow)

                    PromptParticlesView()
                        .frame(width: 260, height: 160)

                    TypewriterText(text: word,
                                   characterDelay: 0.09,
                                   initialDelay: 0.1)
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(colors: [Color.white, Color.yellow.opacity(0.82)],
                                       startPoint: .top,
                                       endPoint: .bottom)
                    )
                    .shadow(color: .yellow.opacity(0.35), radius: 16, x: 0, y: 0)
                }
                .padding(.horizontal, 20)

                if showButton {
                    Button(action: onContinue) {
                        Text("Commencer à dessiner")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)
            .scaleEffect(showContent ? 1 : 0.94)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)

            withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) {
                showContent = true
                shouldPulseGlow = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                    showButton = true
                }
            }
        }
    }
}

struct TypewriterText: View {
    let text: String
    var characterDelay: TimeInterval = 0.08
    var initialDelay: TimeInterval = 0

    @State private var displayedText = ""
    @State private var timer: Timer?

    var body: some View {
        Text(displayedText)
            .onAppear(perform: startTyping)
            .onDisappear(perform: stopTyping)
    }

    private func startTyping() {
        displayedText = ""
        stopTyping()

        let characters = Array(text)
        guard !characters.isEmpty else { return }

        var currentIndex = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            timer = Timer.scheduledTimer(withTimeInterval: characterDelay, repeats: true) { newTimer in
                guard currentIndex < characters.count else {
                    newTimer.invalidate()
                    return
                }

                displayedText.append(characters[currentIndex])
                currentIndex += 1
            }
        }
    }

    private func stopTyping() {
        timer?.invalidate()
        timer = nil
    }
}

private struct PromptParticlesView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .offset(y: animate ? -65 : -42)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .blur(radius: animate ? 0.2 : 0)
                    .opacity(animate ? 0 : 1)
                    .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.08), value: animate)
            }
        }
        .onAppear { animate = true }
    }
}
