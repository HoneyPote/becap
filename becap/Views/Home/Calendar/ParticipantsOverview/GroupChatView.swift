//
//  GroupChatView.swift
//  becap
//
//  Created by OpenAI on 05/08/2025.
//

import SwiftUI

struct GroupChatView: View {
    @Environment(\.dismiss) private var dismiss

    let messages: [ChallengeChatMessage]
    let currentUserId: String?
    let onSendMessage: (String) async -> Void
    let onToggleReaction: (ChallengeChatMessage, String) async -> Void

    @State private var messageDraft: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var displayedMessages: [ChallengeChatMessage] = []

    private let availableReactions = ["👍", "🔥", "👏", "❤️", "😂", "😮"]

    var body: some View {
        NavigationStack {
            ZStack {
                Image("iphone_wallpaper_forest")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Color.black.opacity(0.25)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            if displayedMessages.isEmpty {
                                emptyState
                            } else {
                                LazyVStack(alignment: .leading, spacing: 16) {
                                    ForEach(displayedMessages) { message in
                                        GroupChatMessageRow(
                                            message: message,
                                            isCurrentUser: message.senderId == currentUserId,
                                            currentUserId: currentUserId,
                                            availableReactions: availableReactions,
                                            onToggleReaction: { reaction in
                                                Task {
                                                    await onToggleReaction(message, reaction)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                                .padding(.bottom, 16)
                            }
                        }
                        .onChange(of: displayedMessages.count) { _ in
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: messages) { newValue in
                            displayedMessages = newValue
                        }
                        .onAppear {
                            displayedMessages = messages
                            scrollToBottom(proxy: proxy, animated: false)
                        }
                    }

                    chatInput
                        .background(.thinMaterial)
                }
            }
            .navigationTitle("Chat du groupe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Fermer le chat")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 42, weight: .light))
                .foregroundColor(.white.opacity(0.4))

            Text("Pas encore de messages")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundColor(.white.opacity(0.75))

            Text("Dis bonjour à tout le monde et lance la conversation ✨")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var chatInput: some View {
        HStack(spacing: 12) {
            TextField("Écrire un message...", text: $messageDraft)
                .textFieldStyle(.plain)
                .focused($isInputFocused)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                        )
                )
                .foregroundColor(.white)

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(isSendDisabled ? 0.15 : 0.28))
                    )
            }
            .disabled(isSendDisabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var isSendDisabled: Bool {
        messageDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendMessage() {
        let trimmed = messageDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let toSend = trimmed
        messageDraft = ""

        Task {
            await onSendMessage(toSend)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard let lastId = displayedMessages.last?.id else { return }

        DispatchQueue.main.async {
            withAnimation(animated ? .easeOut(duration: 0.25) : nil) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}
