//
//  MedalPopupView.swift
//  becap ap
//
//  Created by Adam Mabrouki on 26/07/2025.
//

import SwiftUI
import AVFoundation

struct MedalPopupView: View {
    @State private var animate = false
    @State private var player: AVAudioPlayer?

    let medals: [UserMedal]
    let onDismiss: () -> Void

    var body: some View {
        let primaryMedal = medals.first

        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 16) {
                Text(medals.count > 1 ? "Nouvelles médailles !" : "Nouvelle médaille !")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.yellow)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                if let primaryMedal {
                    MedalIconView(iconName: primaryMedal.iconName)
                        .frame(width: 60, height: 60)
                        .scaleEffect(animate ? 1.2 : 0.8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: animate)

                    Text(primaryMedal.name)
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)

                    Text(primaryMedal.description)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if medals.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aujourd'hui tu as débloqué :")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)

                        ForEach(Array(medals.dropFirst().enumerated()), id: \.offset) { _, medal in
                            HStack(spacing: 8) {
                                MedalIconView(iconName: medal.iconName)
                                    .frame(width: 22, height: 22)
                                Text(medal.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 12) {
                    if let primaryMedal {
                        if #available(iOS 16.0, *) {
                            ShareLink(item: "J'ai débloqué \(primaryMedal.name) sur becap !") {
                                Label("Partager", systemImage: "square.and.arrow.up")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }

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
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .padding(32)
            .shadow(radius: 12)
        }
        .onAppear {
            animate = true
            playSound(isBundle: medals.count > 1)
            vibrate()
        }
    }

    // TODO: Mettre ces méthode dans un vm
    private func playSound(isBundle: Bool) {
        let resource = isBundle ? "success" : "success"
        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp3") else { return }
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
