//
//  ParticipantsOverviewView.swift
//  becap
//
//  Created by OpenAI on 05/08/2025.
//

import SwiftUI

struct ParticipantsOverviewView: View {
    let participants: [Participant]
    let photos: [ChallengePhoto]
    let progresses: [ParticipantProgress]
    let chatMessages: [ChallengeChatMessage]
    let hasUnreadMessages: Bool
    let currentUserId: String?
    let onSendMessage: (String) async -> Void
    let onChatOpened: () -> Void

    @State private var showingChat = false

    private struct ParticipantStats {
        let photosCount: Int
        let likesCount: Int
        let streak: Int
        let validatedDays: Int
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.petrolToSky.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(participants, id: \.self) { participant in
                            GlassCard {
                                ParticipantCardContent(
                                    participant: participant,
                                    stats: stats(for: participant)
                                )
                            }
                        }

                        GlassCard {
                            GroupChatCard(
                                messages: chatMessages,
                                hasUnreadMessages: hasUnreadMessages,
                                onOpenChat: {
                                    showingChat = true
                                    onChatOpened()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("Participants")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingChat) {
            GroupChatView(
                messages: chatMessages,
                currentUserId: currentUserId,
                onSendMessage: onSendMessage
            )
        }
        .onChange(of: chatMessages.count) { _ in
            if showingChat {
                onChatOpened()
            }
        }
    }

    private func stats(for participant: Participant) -> ParticipantStats {
        let participantPhotos = photos.filter { $0.authorUid == participant.id }
        let likes = participantPhotos.reduce(0) { partialResult, photo in
            partialResult + (photo.likes?.count ?? 0)
        }
        let progress = progresses.first { $0.id == participant.id }

        return ParticipantStats(
            photosCount: participantPhotos.count,
            likesCount: likes,
            streak: progress?.currentStreak ?? 0,
            validatedDays: progress?.validatedDays.count ?? 0
        )
    }
}

private struct ParticipantCardContent: View {
    let participant: Participant
    let stats: ParticipantsOverviewView.ParticipantStats

    @State private var showingMedals = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                ParticipantAvatarView(name: participant.name, photoURL: participant.photoURL)

                VStack(alignment: .leading, spacing: 6) {
                    Text(participant.name)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)
                    Text("Fait partie du défi")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }

            StatsGrid(stats: stats)

            MedalTriggerRow(
                participant: participant,
                showingMedals: $showingMedals
            )
        }
        .popover(isPresented: $showingMedals, arrowEdge: .top) {
            MedalBubbleView(medals: participant.medals)
        }
    }
}

private struct MedalTriggerRow: View {
    let participant: Participant
    @Binding var showingMedals: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Médailles")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.white.opacity(0.85))

                Text(participant.medals.isEmpty ? "Aucune médaille pour le moment" : "\(participant.medals.count) médailles")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if !participant.medals.isEmpty {
                Button {
                    showingMedals = true
                } label: {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Voir les médailles de \(participant.name)")
            }
        }
    }
}

private struct MedalBubbleView: View {
    let medals: [UserMedal]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Médailles")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            Divider()
                .background(Color.white.opacity(0.3))

            if medals.isEmpty {
                Text("Aucune médaille pour le moment")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                ScrollView {
                    ParticipantMedalSection(medals: medals)
                }
                .frame(maxHeight: 260)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)
    }
}

private struct GroupChatCard: View {
    let messages: [ChallengeChatMessage]
    let hasUnreadMessages: Bool
    let onOpenChat: () -> Void

    private var lastMessage: ChallengeChatMessage? { messages.last }

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

            VStack(alignment: .leading, spacing: 6) {
                Text(lastMessageTitle)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)

                Text(lastMessagePreview)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }

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
            .buttonStyle(.plain)
            .accessibilityLabel("Ouvrir le chat du groupe")
        }
    }

    private var lastMessageTitle: String {
        guard let lastMessage else {
            return "Commencez la discussion"
        }

        return "Dernier message de \(lastMessage.senderName)"
    }

    private var lastMessagePreview: String {
        guard let lastMessage else {
            return "Personne n'a encore écrit dans le chat. Lance la conversation !"
        }

        return lastMessage.content
    }

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

private struct StatsGrid: View {
    let stats: ParticipantsOverviewView.ParticipantStats

    private var gridItems: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 12) {
            StatBadge(title: "Photos", value: "\(stats.photosCount)")
            StatBadge(title: "Likes", value: "\(stats.likesCount)")
            StatBadge(title: "Streak", value: "\(stats.streak) j")
            StatBadge(title: "Validées", value: "\(stats.validatedDays)")
        }
    }
}

private struct StatBadge: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)
            Text(title)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct GroupChatView: View {
    @Environment(\.dismiss) private var dismiss

    let messages: [ChallengeChatMessage]
    let currentUserId: String?
    let onSendMessage: (String) async -> Void

    @State private var messageDraft: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        if messages.isEmpty {
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
                        } else {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                ForEach(messages) { message in
                                    GroupChatMessageRow(
                                        message: message,
                                        isCurrentUser: message.senderId == currentUserId
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 16)
                        }
                    }
                    .onChange(of: messages.count) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy, animated: false)
                    }
                }

                chatInput
                    .background(.thinMaterial)
            }
            .background(LinearGradient.petrolToSky.ignoresSafeArea())
            .navigationTitle("Chat du groupe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
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
        guard let lastId = messages.last?.id else { return }

        DispatchQueue.main.async {
            withAnimation(animated ? .easeOut(duration: 0.25) : nil) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

private struct GroupChatMessageRow: View {
    let message: ChallengeChatMessage
    let isCurrentUser: Bool

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 6) {
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
}

private struct ParticipantAvatarView: View {
    let name: String
    let photoURL: String?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.18))
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                )

            if let photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        ProgressView()
                    case .failure:
                        initialsView
                    @unknown default:
                        initialsView
                    }
                }
                .clipShape(Circle())
            } else {
                initialsView
            }
        }
        .frame(width: 64, height: 64)
    }

    private var initialsView: some View {
        Text(initials(from: name))
            .font(.system(.title2, design: .rounded).weight(.heavy))
            .foregroundColor(.white)
    }

    private func initials(from name: String) -> String {
        let components = name.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }
        return String(initials)
    }
}
