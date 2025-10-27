//
//  GroupChatMessageRow.swift
//  becap
//
//  Created by OpenAI on 05/08/2025.
//

import SwiftUI

struct GroupChatMessageRow: View {
    let message: ChallengeChatMessage
    let isCurrentUser: Bool
    let currentUserId: String?
    let availableReactions: [String]
    let onToggleReaction: (String) -> Void

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 8) {
            if !isCurrentUser {
                Text(message.senderName)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(.white.opacity(0.7))
            }

            Text(message.content)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(bubbleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if !message.reactions.isEmpty || canReact {
                reactionStack
            }

            Text(Self.timeFormatter.string(from: message.createdAt))
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
    }

    private var bubbleBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                isCurrentUser
                ? Color.white.opacity(0.26)
                : Color.white.opacity(0.14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(isCurrentUser ? 0.35 : 0.18), lineWidth: 0.8)
            )
    }

    private var reactionStack: some View {
        HStack(spacing: 8) {
            ForEach(reactionEntries, id: \.emoji) { entry in
                Button {
                    onToggleReaction(entry.emoji)
                } label: {
                    ReactionBadge(
                        emoji: entry.emoji,
                        count: entry.users.count,
                        isHighlighted: entry.users.contains(where: { $0 == currentUserId })
                    )
                }
                .buttonStyle(.plain)
            }

            if canReact {
                Menu {
                    ForEach(availableReactions, id: \.self) { reaction in
                        Button {
                            onToggleReaction(reaction)
                        } label: {
                            let hasReacted = userHasReacted(to: reaction)
                            Text("\(reaction) " + (hasReacted ? "Retirer" : "Ajouter"))
                        }
                    }
                } label: {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Ajouter une réaction")
            }
        }
        .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
    }

    private var reactionEntries: [(emoji: String, users: [String])]
    {
        message.reactions
            .map { (key: String, value: [String]) -> (emoji: String, users: [String]) in
                (emoji: key, users: value)
            }
            .filter { !$0.users.isEmpty }
            .sorted { lhs, rhs in
                if lhs.users.count == rhs.users.count {
                    return lhs.emoji < rhs.emoji
                }
                return lhs.users.count > rhs.users.count
            }
    }

    private var canReact: Bool { currentUserId != nil }

    private func userHasReacted(to reaction: String) -> Bool {
        guard let currentUserId else { return false }
        return message.reactions[reaction]?.contains(currentUserId) ?? false
    }

    private struct ReactionBadge: View {
        let emoji: String
        let count: Int
        let isHighlighted: Bool

        var body: some View {
            HStack(spacing: 4) {
                Text(emoji)
                Text("\(count)")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(isHighlighted ? 0.32 : 0.18))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isHighlighted ? 0.45 : 0.2), lineWidth: 0.8)
            )
            .foregroundColor(.white)
        }
    }
}
