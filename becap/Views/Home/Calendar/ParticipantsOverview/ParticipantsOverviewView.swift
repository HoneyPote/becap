//
//  ParticipantsOverviewView.swift
//  becap
//
//  Created by OpenAI on 05/08/2025.
//

import SwiftUI

struct ParticipantsOverviewView: View {
    @Environment(\.dismiss) private var dismiss

    let participants: [Participant]
    let photos: [ChallengePhoto]
    let progresses: [ParticipantProgress]
    let chatMessages: [ChallengeChatMessage]
    let hasUnreadMessages: Bool
    let currentUserId: String?
    let onSendMessage: (String) async -> Void
    let onToggleReaction: (ChallengeChatMessage, String) async -> Void
    let onChatOpened: () -> Void

    @State private var showingChat = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.petrolToSky.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard {
                            GroupChatCardView(
                                messages: chatMessages,
                                hasUnreadMessages: hasUnreadMessages,
                                onOpenChat: {
                                    showingChat = true
                                    onChatOpened()
                                }
                            )
                        }

                        ForEach(participants, id: \.self) { participant in
                            GlassCard {
                                ParticipantCardView(
                                    participant: participant,
                                    stats: stats(for: participant)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("Participants")
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
                    .accessibilityLabel("Fermer")
                }
            }
        }
        .sheet(isPresented: $showingChat) {
            GroupChatView(
                messages: chatMessages,
                currentUserId: currentUserId,
                onSendMessage: onSendMessage,
                onToggleReaction: onToggleReaction
            )
        }
        .onChange(of: chatMessages.count) { _ in
            if showingChat {
                onChatOpened()
            }
        }
    }

    private func stats(for participant: Participant) -> ParticipantOverviewStats {
        let participantPhotos = photos.filter { $0.authorUid == participant.id }
        let likes = participantPhotos.reduce(0) { partialResult, photo in
            partialResult + (photo.likes?.count ?? 0)
        }
        let progress = progresses.first { $0.id == participant.id }

        return ParticipantOverviewStats(
            photosCount: participantPhotos.count,
            likesCount: likes,
            streak: progress?.currentStreak ?? 0,
            validatedDays: progress?.validatedDays.count ?? 0
        )
    }
}
