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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let infoText = challenge.infoText, !infoText.isEmpty {
                Text(infoText)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            } else {
                Text("Découvrez ce défi premium avant de le débloquer.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            if let videoURL = challenge.infoVideoURL, let url = URL(string: videoURL) {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 140)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .shadow(radius: 8)
    }
}
