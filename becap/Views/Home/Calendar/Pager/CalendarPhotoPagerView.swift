//
//  CalendarPhotoPagerView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//
import SwiftUI


struct CalendarPhotoPagerView: View {
    @StateObject private var viewModel = PhotoViewModel()
    let challengeTitle: String
    let photos: [ChallengePhoto]
    let startIndex: Int
    let canDelete: Bool
    let getParticipant: (String) -> Participant?
    let onDelete: (ChallengePhoto) -> Void
    let onClose: () -> Void

    @State private var selection: Int

    init(
        challengeTitle: String,
        photos: [ChallengePhoto],
        startIndex: Int = 0,
        canDelete: Bool,
        getParticipant: @escaping (String) -> Participant?,
        onDelete: @escaping (ChallengePhoto) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.challengeTitle = challengeTitle
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
                                AsyncPhotoPagerView(photo: photos[idx])
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
                                // --- Like section ---
                                if let livePhoto = viewModel.currentPhoto, livePhoto.id == photos[idx].id {
                                    LikeSection(
                                        photo: livePhoto,
                                        challengeId: livePhoto.challengeId ?? "",
                                        likeAction: { userId in
                                            // Passer par le viewModel pour gérer la notif !
                                            viewModel.like(
                                                photo: livePhoto,
                                                userId: userId,
                                                userName: UserManager.shared.currentUser?.name ?? "",
                                                challengeTitle: challengeTitle
                                            )
                                        },
                                        unlikeAction: { userId in
                                            viewModel.unlike(photo: livePhoto, userId: userId)
                                        },
                                        getParticipant: getParticipant
                                    )
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
        .onAppear {
                   listenToCurrentPhoto()
               }
               .onChange(of: selection) { _ in
                   listenToCurrentPhoto()
               }
    }


    private var currentPhoto: ChallengePhoto? {
        guard !photos.isEmpty, selection < photos.count else { return nil }
        return photos[selection]
    }

    private func listenToCurrentPhoto() {
        guard !photos.isEmpty, selection < photos.count,
              let challengeId = photos[selection].challengeId,
              let photoId = photos[selection].id
        else { return }
        viewModel.listenToPhotoRealtime(challengeId: challengeId, photoId: photoId)
    }
}
