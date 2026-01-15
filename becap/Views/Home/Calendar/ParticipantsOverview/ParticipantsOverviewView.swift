//
//  ParticipantsOverviewView.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//

import SwiftUI

struct ParticipantsOverviewView: View {
    @StateObject private var viewModel: ParticipantOverviewViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingChat = false

    let onChallengeQuit: () -> Void

    init(challenge: Challenge, participants: [ParticipantUIModel], onChallengeQuit: @escaping () -> Void) {
        self.onChallengeQuit = onChallengeQuit
        _viewModel = StateObject(wrappedValue: ParticipantOverviewViewModel(challenge: challenge,
                                                                            participants: participants))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.petrolToSky.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard {
                            GroupChatCardView(hasUnreadMessages: viewModel.hasUnreadMessages,
                                              onOpenChat: { showingChat = true })
                        }

                        ForEach(viewModel.participants, id: \.self) { participant in
                            GlassCard {
                                ParticipantCardView(viewModel: viewModel,
                                                    participant: participant,
                                                    stats: viewModel.buildParticipantStats(for: participant),
                                                    onChallengeQuit: {
                                    dismiss()
                                    onChallengeQuit()
                                })
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
//                    .buttonStyle(.hapticPlain)
                    .accessibilityLabel("Fermer")
                }
            }
        }
        .sheet(isPresented: $showingChat) {
            GroupChatView(challenge: viewModel.challenge)
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text(viewModel.alertTitle),
                  message: Text(viewModel.alertMessage),
                  dismissButton: .default(Text("OK")))
        }
    }
}
