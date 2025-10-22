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

     struct ParticipantStats {
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("Participants")
            .navigationBarTitleDisplayMode(.inline)
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

            VStack(alignment: .leading, spacing: 8) {
                Text("Médailles")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.white.opacity(0.85))

                if participant.medals.isEmpty {
                    Text("Aucune médaille pour le moment")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    ParticipantMedalSection(medals: participant.medals)
                }
            }
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
