//
//  GroupChatMessageRow.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//

import SwiftUI

struct GroupChatMessageRow: View {
    @ObservedObject var viewModel: GroupChatViewModel

    @State private var isShowingReactionPicker: Bool = false

    let message: ChallengeChatMessage
    let availableReactions = ["👍", "🔥", "👏", "❤️", "😂", "😮"]

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: viewModel.isFromCurrentUser(message) ? .trailing : .leading, spacing: 8) {
            if !viewModel.isFromCurrentUser(message) {
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
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 0.35) {
                    isShowingReactionPicker = true
                }

            if !message.reactions.isEmpty {
                reactionStack
            }

            Text(Self.timeFormatter.string(from: message.createdAt))
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: viewModel.isFromCurrentUser(message) ? .trailing : .leading)
        .confirmationDialog("Réagir au message", isPresented: $isShowingReactionPicker, titleVisibility: .visible) {
            ForEach(availableReactions, id: \.self) { reaction in
                Button {
                    viewModel.toggleReaction(reaction, for: message)
                } label: {
                    Text(viewModel.hasReacted(to: message, with: reaction))
                }

//                Text(viewModel.hasReacted(to: message, with: reaction))
//                    .onTapGesture { viewModel.toggleReaction(reaction, for: message) }
            }

            Button("Annuler", role: .cancel) { }
        }
    }

    private var bubbleBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(viewModel.isFromCurrentUser(message) ? Color.white.opacity(0.26) : Color.white.opacity(0.14))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(viewModel.isFromCurrentUser(message) ? 0.35 : 0.18), lineWidth: 0.8)
            )
    }

    private var reactionStack: some View {
        HStack(spacing: 8) {
            ForEach(reactionEntries, id: \.emoji) { entry in
                Button {
                    viewModel.toggleReaction(entry.emoji, for: message)
                } label: {
                    ReactionBadge(emoji: entry.emoji,
                                  count: entry.users.count,
                                  isHighlighted: viewModel.reactionBadgeIsHighlighted(entryUsers: entry.users))
                }
                .buttonStyle(.hapticPlain)
            }

        }
        .frame(maxWidth: .infinity, alignment: viewModel.isFromCurrentUser(message) ? .trailing : .leading)
    }

    private var reactionEntries: [(emoji: String, users: [String])] {
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
