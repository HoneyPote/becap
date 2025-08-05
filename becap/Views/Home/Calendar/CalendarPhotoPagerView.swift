//
//  CalendarPhotoPagerView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//
import SwiftUI

import SwiftUI

struct CalendarPhotoPagerView: View {
    let photos: [ChallengePhoto]
    let startIndex: Int
    let canDelete: Bool
    let getParticipant: (String) -> Participant?
    let onDelete: (ChallengePhoto) -> Void
    let onClose: () -> Void

    @State private var selection: Int

    init(
        photos: [ChallengePhoto],
        startIndex: Int = 0,
        canDelete: Bool,
        getParticipant: @escaping (String) -> Participant?,
        onDelete: @escaping (ChallengePhoto) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.photos = photos
        self.startIndex = startIndex
        self.canDelete = canDelete
        self.getParticipant = getParticipant
        self.onDelete = onDelete
        self.onClose = onClose
        _selection = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient.petrolToSky.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.title2.bold())
                            .padding(8)
                            .background(Color.black.opacity(0.22))
                            .clipShape(Circle())
                    }
                    Spacer()
                    if let name = currentPhoto?.authorName {
                        Text(name)
                            .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    Spacer()
                }
                .padding(.top, 26)
                .padding(.horizontal, 18)
                .padding(.bottom, 6)

                if photos.isEmpty {
                    Spacer()
                    Text("Aucune photo")
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    TabView(selection: $selection) {
                        ForEach(photos.indices, id: \.self) { idx in
                            VStack(spacing: 12) {
                                // Photo
                                AsyncPhotoView(photo: photos[idx])
                                    .frame(maxHeight: 410)
                                    .padding(.top, 8)

                                // Médailles juste sous le prénom
                                if let participant = getParticipant(photos[idx].authorUid) {
                                    MedalsSection(medals: participant.medals)
                                        .padding(.bottom, 6)
                                }

                                // Description
                                if let desc = photos[idx].description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.85))
                                        .padding(.top, 2)
                                }

                                // Date
                                Text(photos[idx].date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.top, 2)
                            }
                            .padding(.horizontal)
                            .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                    .animation(.default, value: selection)

                    if canDelete {
                        HStack {
                            Spacer()
                            Button(role: .destructive) {
                                if !photos.isEmpty, selection < photos.count {
                                    onDelete(photos[selection])
                                }
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                                    .foregroundColor(.red)
                                    .padding(8)
                                    .background(.thinMaterial)
                                    .clipShape(Capsule())
                            }
                            .padding(.trailing, 16)
                        }
                        .frame(height: 44)
                    }
                }
            }
            .padding(.top, 0) // <- Important : limite l'espace au-dessus du header
        }
    }

    private var currentPhoto: ChallengePhoto? {
        guard !photos.isEmpty, selection < photos.count else { return nil }
        return photos[selection]
    }
}

private struct AsyncPhotoView: View {
    let photo: ChallengePhoto

    var body: some View {
        Group {
            if let url = URL(string: photo.imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(18)
                            .shadow(radius: 18)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }
        }
    }
}

private struct MedalsSection: View {
    let medals: [UserMedal]

    var body: some View {
        if !medals.isEmpty {
            VStack(spacing: 2) {
                Text("Médailles obtenues par le joueur:")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.83))
                HStack(spacing: 6) {
                    ForEach(medals, id: \.id) { medal in
                        MedalIconView(iconName: medal.iconName)
                            .frame(width: 28, height: 28)
                            .shadow(color: Color.black.opacity(0.13), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .padding(.top, 4)
        }
    }
}
