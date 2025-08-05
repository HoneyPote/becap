//
//  MedalPopupView.swift
//  becap
//
//  Created by Adam Mabrouki on 26/07/2025.
//

import SwiftUI
import AVFoundation

struct MedalPopupView: View {
    let medal: UserMedal
    let onDismiss: () -> Void

    @State private var animate = false
    @State private var player: AVAudioPlayer?

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Nouvelle médaille !")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.yellow)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                Image(medal.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .scaleEffect(animate ? 1.2 : 0.8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.5), value: animate)

                Text(medal.name)
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)

                Text(medal.description)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Fermer") {
                    withAnimation {
                        onDismiss()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.8))
                .cornerRadius(12)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .padding(32)
            .shadow(radius: 12)
        }
        .onAppear {
            animate = true
            playSound()
            vibrate()
        }
    }

    private func playSound() {
        guard let url = Bundle.main.url(forResource: "success", withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("❌ Erreur son: \(error.localizedDescription)")
        }
    }

    private func vibrate() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
