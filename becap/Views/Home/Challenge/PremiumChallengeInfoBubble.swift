//
//  PremiumChallengeInfoBubble.swift
//  becap
//
//  Created by OpenAI on 2025-02-14.
//

import SwiftUI
import AVKit

//struct PremiumChallengeInfoBubble: View {
//    let challenge: PremiumChallenge
//    let onClose: () -> Void
//
//    var body: some View {
//        VStack(spacing: 16) {
//            HStack {
//                Text(challenge.title)
//                    .font(.title3.weight(.semibold))
//                    .foregroundColor(.primary)
//                    .multilineTextAlignment(.leading)
//
//                Spacer()
//
//                Button(action: onClose) {
//                    Image(systemName: "xmark.circle.fill")
//                        .font(.title2)
//                        .foregroundStyle(.secondary)
//                }
//                .accessibilityLabel("Fermer la présentation du défi premium")
//            }
//
//            switch challenge.media {
//            case .text(let description):
//                ScrollView {
//                    Text(description)
//                        .font(.body)
//                        .foregroundColor(.primary)
//                        .multilineTextAlignment(.leading)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .padding(.vertical, 4)
//                }
//                .frame(maxHeight: 220)
//
//            case .video(let url):
//                VideoPlayer(player: AVPlayer(url: url))
//                    .frame(height: 220)
//                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//            }
//
//            Label(
//                title: {
//                    Text(String(format: "%.2f %@", NSDecimalNumber(decimal: challenge.price).doubleValue, challenge.currencyCode))
//                        .font(.headline)
//                },
//                icon: {
//                    Image(systemName: "eurosign.circle")
//                        .font(.headline)
//                }
//            )
//            .foregroundStyle(.secondary)
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .padding(20)
//        .background(.ultraThinMaterial)
//        .background(
//            RoundedRectangle(cornerRadius: 24, style: .continuous)
//                .fill(Color.white)
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
//        .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 14)
//        .padding(24)
//    }
//}
//
//
