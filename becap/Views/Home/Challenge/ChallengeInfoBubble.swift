//
//  ChallengeInfoBubble.swift
//  becap
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//

import SwiftUI
import AVKit

struct ChallengeInfoBubble: View {
    let challenge: Challenge

    @State private var player = AVPlayer()
    @State private var loadedVideoURL: URL?

    private var promoVideoURL: URL? {
        if let infoVideoURL = challenge.infoVideoURL, let remoteURL = URL(string: infoVideoURL) {
            return remoteURL
        }

        return Bundle.main.url(forResource: "dégradéBleu", withExtension: "mp4")
    }

    private var infoDescription: String {
        if let infoText = challenge.infoText, !infoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return infoText
        }

        return "Débloquez ce challenge premium pour accéder à un programme guidé, des checkpoints quotidiens et des récompenses exclusives."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let videoURL = promoVideoURL {
                VideoPlayer(player: player)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        Text("Aperçu vidéo")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(10)
                    }
                    .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 8)
                    .onAppear {
                        configurePlayerIfNeeded(with: videoURL)
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                        player.seek(to: .zero)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(challenge.title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)

                Text(infoDescription)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Programme structuré sur \(challenge.duration) jours", systemImage: "calendar.badge.clock")
                Label("Suivi et relances push quotidiennes", systemImage: "bell.badge.fill")
                Label("Récompenses et accès à la communauté", systemImage: "person.3.fill")
            }
            .font(.footnote.weight(.semibold))
            .foregroundColor(.primary)
            .labelStyle(.titleAndIcon)
            .symbolRenderingMode(.hierarchical)

            HStack {
                Text(challenge.formattedPrice)
                    .font(.callout.weight(.bold))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(Color.blue.opacity(0.12), in: Capsule())
                Spacer()
                Text("Paiement sécurisé Apple Pay ou carte")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 6)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 10)
    }
}

private extension ChallengeInfoBubble {
    func configurePlayerIfNeeded(with url: URL) {
        guard loadedVideoURL != url else { return }

        loadedVideoURL = url
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
    }
}
