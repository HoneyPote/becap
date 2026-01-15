//
//  GroupChatCardView.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//

import SwiftUI

struct GroupChatCardView: View {
    let hasUnreadMessages: Bool
    let onOpenChat: () -> Void

//    private var lastMessage: ChallengeChatMessage? { messages.last }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                Text("Chat du groupe")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundColor(.white)

                Spacer()

                if hasUnreadMessages {
                    NotificationDot()
                        .transition(.opacity)
                }
            }

//            VStack(alignment: .leading, spacing: 6) {
//                Text(lastMessageTitle)
//                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
//                    .foregroundColor(.white.opacity(0.85))
//                    .lineLimit(1)
//
//                Text(lastMessagePreview)
//                    .font(.system(.footnote, design: .rounded))
//                    .foregroundColor(.white.opacity(0.6))
//                    .lineLimit(2)
//            }

            Button(action: onOpenChat) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 42, height: 42)

                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("Ouvrir le chat")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
                        )
                )
                .overlay(alignment: .topTrailing) {
                    if hasUnreadMessages {
                        NotificationDot(size: 10)
                            .offset(x: 8, y: -8)
                    }
                }
            }
//            .buttonStyle(.hapticPlain)
            .accessibilityLabel("Ouvrir le chat du groupe")
        }
    }

//    private var lastMessageTitle: String {
//        guard let lastMessage else {
//            return "Commencez la discussion"
//        }
//
//        return "Dernier message de \(lastMessage.senderName)"
//    }
//
//    private var lastMessagePreview: String {
//        guard let lastMessage else {
//            return "Personne n'a encore écrit dans le chat. Lance la conversation !"
//        }
//
//        return lastMessage.content
//    }

    private struct NotificationDot: View {
        var size: CGFloat = 12

        var body: some View {
            Circle()
                .fill(Color(red: 1.0, green: 0.34, blue: 0.36))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 0.8)
                )
        }
    }
}
