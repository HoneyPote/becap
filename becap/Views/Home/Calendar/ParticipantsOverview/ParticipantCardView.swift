//
//  ParticipantCardView.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//

import SwiftUI

struct ParticipantOverviewStats {
    let postsCount: Int
    let likesCount: Int
    let streak: Int
    let validatedDays: Int
    let totalJokers: Int
    let remainingJokers: Int
}

struct ParticipantCardView: View {
    @ObservedObject var viewModel: ParticipantOverviewViewModel

    let participant: ParticipantUIModel
    let stats: ParticipantOverviewStats
    let onChallengeQuit: () -> Void

    @State private var showingMedals = false
    @State private var showPromoteConfirmation = false
    @State private var showExclusionConfirmation = false
    @State private var showQuitConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                ParticipantAvatarView(name: participant.userName, photoURL: participant.userProfilePhotoURL)

                VStack(alignment: .leading, spacing: 6) {
                    if let titles = viewModel.participantTitles(participant: participant) {
                        Text(titles)
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Text(participant.userName)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)
                    Text(participant.progress.isBlocked
                         ? "Ne fait plus partie du défi"
                         : "Fait partie du défi")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(participant.progress.isBlocked ? .red.opacity(0.7) : .white.opacity(0.7))
                }

                Spacer()

                if viewModel.showPromoteToAdminButton(for: participant) {
                    Button(action: { showPromoteConfirmation = true }) {
                        Image(systemName: "laurel.leading.laurel.trailing")
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
                }
            }

            ParticipantStatsGrid(stats: stats)

            if stats.totalJokers > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    if stats.remainingJokers == 0 {
                        Text("Aucun joker restant")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    } else {
                        Text("Jokers restants")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(.white.opacity(0.8))

                        HStack(spacing: 8) {
                            let displayCount = min(stats.totalJokers, 8)

                            ForEach(0..<displayCount, id: \.self) { index in
                                let isActive = index < min(stats.remainingJokers, displayCount)
                                JokerIconView(size: 26, isDimmed: !isActive)
                            }

                            if stats.remainingJokers > displayCount {
                                Text("+\(stats.remainingJokers - displayCount)")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                }
            }

            if !participant.userMedals.isEmpty {
                MedalTriggerRow(medalCount: participant.userMedals.count,
                                participantName: participant.userName,
                                onTap: { showingMedals = true })
            }

            if viewModel.showQuitButton(for: participant) {
                Button {
                    showQuitConfirmation = true
                } label: {
                    Text("Quitter le défi")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.plain)
            } else if viewModel.showBlockParticipantButton(for: participant) {
                Button {
                    showExclusionConfirmation = true
                } label: {
                    Text("Exclure du défi")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.plain)
            }
        }
        .alert("Promouvoir en tant qu'administrateur ?", isPresented: $showPromoteConfirmation) {
            Button("Annuler", role: .cancel) {}

            Button("Confirmer", role: .destructive) {
                viewModel.promoteToAdmin(userId: participant.userId)
            }
        } message: {
            Text("Voulez-vous vraiment promouvoir \(participant.userName) en tant qu’administrateur du défi ? Cette personne détiendra le droit d'exclure des participants du défi, ainsi que de nommer d'autres participants comme adminitrateur.")
        }
        .alert("Exclure du défi ?", isPresented: $showExclusionConfirmation) {
            Button("Annuler", role: .cancel) {}

            Button("Confirmer", role: .destructive) {
                viewModel.blockParticipant(userId: participant.userId)
            }
        } message: {
            Text("Voulez-vous vraiment exclure \(participant.userName) du défi ? Cette personne apparaitera encore dans la liste des participants, mais ne pourra plus intéragir avec le défi.")
        }
        .alert("Quitter le défi ?", isPresented: $showQuitConfirmation) {
            Button("Annuler", role: .cancel) {}

            Button("Confirmer", role: .destructive) {
                viewModel.quitChallenge() { hasQuit in
                    if hasQuit {
                        onChallengeQuit()
                    }
                }
            }
        } message: {
            Text("Voulez-vous vraiment quitter le défi ? Vous apparaiterez encore dans la liste des participants, mais ne pourrez plus intéragir avec le défi.")
        }
        .popover(isPresented: $showingMedals, arrowEdge: .top) {
            MedalBubbleView(medals: participant.userMedals)
        }
    }
}
