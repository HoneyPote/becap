////
////  CalendarPhotoPagerView.swift
////  becap
////
////  Created by Adam Mabrouki on 15/07/2025.
////
//import SwiftUI
//
//
//struct CalendarPhotoPagerView: View {
//    @StateObject private var viewModel = PhotoViewModel()
//    let challengeTitle: String
//    let photos: [ChallengePhoto]
//    let startIndex: Int
//    let canDelete: Bool
//    let getParticipant: (String) -> Participant?
//    let onDelete: (ChallengePhoto) -> Void
//    let onClose: () -> Void
//
//
//    @State private var selection: Int
//    @FocusState private var isTextFieldFocused: Bool
//    @StateObject private var keyboard = KeyboardResponder()
//
//    init(
//        challengeTitle: String,
//        photos: [ChallengePhoto],
//        startIndex: Int = 0,
//        canDelete: Bool,
//        getParticipant: @escaping (String) -> Participant?,
//        onDelete: @escaping (ChallengePhoto) -> Void,
//        onClose: @escaping () -> Void
//    ) {
//        self.challengeTitle = challengeTitle
//        self.photos = photos
//        self.startIndex = startIndex
//        self.canDelete = canDelete
//        self.getParticipant = getParticipant
//        self.onDelete = onDelete
//        self.onClose = onClose
//        _selection = State(initialValue: startIndex)
//    }
//
//    var body: some View {
//           ZStack(alignment: .top) {
//               LinearGradient.petrolToSky.ignoresSafeArea()
//
//               VStack(spacing: 0) {
//                   // Header
//                   HStack {
//                       Button(action: onClose) {
//                           Image(systemName: "xmark")
//                               .foregroundColor(.white)
//                               .font(.title2.bold())
//                               .padding(8)
//                               .background(Color.black.opacity(0.22))
//                               .clipShape(Circle())
//                       }
//                       Spacer()
//                       if let name = currentPhoto?.authorName {
//                           Text(name)
//                               .font(.system(.largeTitle, design: .rounded).weight(.heavy))
//                               .foregroundColor(.white)
//                               .lineLimit(1)
//                               .minimumScaleFactor(0.7)
//                       }
//                       Spacer()
//                   }
//                   .padding(.top, 26)
//                   .padding(.horizontal, 18)
//                   .padding(.bottom, 6)
//
//                   // Body
//                   if photos.isEmpty {
//                       Spacer()
//                       Text("Aucune photo")
//                           .foregroundColor(.white)
//                       Spacer()
//                   } else {
//                       TabView(selection: $selection) {
//                           ForEach(photos.indices, id: \.self) { idx in
//                               VStack(spacing: 12) {
//                                   // --- PHOTO + OVERLAY LIKE + DESCRIPTION ---
//                                   ZStack(alignment: .bottomLeading) {
//                                       AsyncPhotoPagerView(photo: photos[idx])
//                                           .frame(height: 410)
//                                           .frame(maxWidth: .infinity)
//                                           .clipped()
//
//                                       VStack(alignment: .leading, spacing: 6) {
//                                           if let desc = photos[idx].description, !desc.isEmpty {
//                                               Text(desc)
//                                                   .font(.body)
//                                                   .foregroundColor(.white)
//                                                   .shadow(radius: 3)
//                                           }
//
//                                           if let livePhoto = viewModel.currentPhoto, livePhoto.id == photos[idx].id {
//                                               LikeSection(
//                                                   photo: livePhoto,
//                                                   challengeId: livePhoto.challengeId ?? "",
//                                                   likeAction: { userId in
//                                                       viewModel.like(
//                                                           photo: livePhoto,
//                                                           userId: userId,
//                                                           userName: UserManager.shared.currentUser?.name ?? "",
//                                                           challengeTitle: challengeTitle
//                                                       )
//                                                   },
//                                                   unlikeAction: { userId in
//                                                       viewModel.unlike(photo: livePhoto, userId: userId)
//                                                   },
//                                                   getParticipant: getParticipant
//                                               )
//                                           }
//                                       }
//                                       .frame(maxWidth: .infinity, alignment: .leading)
//                                       .padding()
//                                       .background(
//                                           LinearGradient(
//                                               gradient: Gradient(colors: [Color.black.opacity(0.7), .clear]),
//                                               startPoint: .bottom,
//                                               endPoint: .top
//                                           )
//                                       )
//                                   }
//                                   .frame(height: 410)
//                                   .frame(maxWidth: .infinity)
//                                   .clipShape(RoundedRectangle(cornerRadius: 20)) // ✅ coupe proprement tout ce qui dépasse
//                                   // Médailles
//                                   if let participant = getParticipant(photos[idx].authorUid) {
//                                       MedalsSection(medals: participant.medals)
//                                           .padding(.bottom, 6)
//                                   }
//
//                                   // --- COMMENTAIRES ---
//                                   ScrollView {
//                                       VStack(spacing: 6) {
//                                           Divider().background(Color.white.opacity(0.3))
//                                           CommentsSection(
//                                               comments: $viewModel.comments,
//                                               isTextFieldFocused: $isTextFieldFocused, 
//                                               onSubmit: { text in
//                                                   if let challengeId = photos[idx].challengeId,
//                                                      let photoId = photos[idx].id {
//                                                       viewModel.addComment(text, challengeId: challengeId, photoId: photoId, challengeTitle: challengeTitle)
//                                                   }
//                                               }
//                                           )
//                                       }
//                                       .scrollDismissesKeyboard(.interactively) // facultatif, swipe to dismiss
//                                       .padding(.bottom, isTextFieldFocused ? 280 : 0) // ajuster selon device
//                                       .animation(.easeInOut(duration: 0.25), value: isTextFieldFocused)
//                                   }
//                                   .frame(maxHeight: 200)
//                                   .background(Color.white.opacity(0.05))
//                                   .clipShape(RoundedRectangle(cornerRadius: 12))
//
//                                   // Date
//                                   Text(photos[idx].date, style: .date)
//                                       .font(.subheadline)
//                                       .foregroundColor(.white.opacity(0.8))
//                                       .padding(.top, 2)
//                               }
//                               .padding(.horizontal)
//                               .tag(idx)
//                           }
//                       }
//                       .tabViewStyle(.page(indexDisplayMode: .always))
//                       .indexViewStyle(.page(backgroundDisplayMode: .interactive))
//                       .animation(.default, value: selection)
//
//                       // Delete button
//                       if canDelete {
//                           HStack {
//                               Spacer()
//                               Button(role: .destructive) {
//                                   if !photos.isEmpty, selection < photos.count {
//                                       onDelete(photos[selection])
//                                   }
//                               } label: {
//                                   Label("Supprimer", systemImage: "trash")
//                                       .foregroundColor(.red)
//                                       .padding(8)
//                                       .background(.thinMaterial)
//                                       .clipShape(Capsule())
//                               }
//                               .padding(.trailing, 16)
//                           }
//                           .frame(height: 44)
//                       }
//                   }
//               }
//               .padding(.top, 0)
//               Spacer().frame(height: keyboard.currentHeight)
//                   .animation(.easeOut(duration: 0.25), value: keyboard.currentHeight)
//           }
//           .onAppear {
//               listenToCurrentPhoto()
//           }
//           .onChange(of: selection) { _ in
//               listenToCurrentPhoto()
//           }
//       }
//
//
//
//    private var currentPhoto: ChallengePhoto? {
//        guard !photos.isEmpty, selection < photos.count else { return nil }
//        return photos[selection]
//    }
//
//
//    private func listenToCurrentPhoto() {
//        guard !photos.isEmpty, selection < photos.count,
//              let challengeId = photos[selection].challengeId,
//              let photoId = photos[selection].id
//        else { return }
//
//        // Écoute les changements de la photo (likes, description, etc.)
//        viewModel.listenToPhotoRealtime(challengeId: challengeId, photoId: photoId)
//
//        // Écoute les commentaires en temps réel pour cette photo
//        viewModel.listenToComments(challengeId: challengeId, photoId: photoId)
//    }
//}
import SwiftUI

struct CalendarPhotoPagerView: View {
    @StateObject private var viewModel = PhotoViewModel()
    @StateObject private var keyboard = KeyboardResponder()

    let challengeTitle: String
    let photos: [ChallengePhoto]
    let startIndex: Int
    let canDelete: Bool
    let getParticipant: (String) -> Participant?
    let onDelete: (ChallengePhoto) -> Void
    let onClose: () -> Void

    @State private var selection: Int
    @FocusState private var isTextFieldFocused: Bool
    @State private var commentText = ""

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
        ZStack(alignment: .bottom) {
            LinearGradient.petrolToSky.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
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
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    Spacer()

                    if canDelete {
                        Button(role: .destructive) {
                            if let photo = currentPhoto {
                                onDelete(photo)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .padding(8)
                                .background(.thinMaterial)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.top, 26)
                .padding(.horizontal, 18)
                .padding(.bottom, 6)

                // Main content
                if photos.isEmpty {
                    Spacer()
                    Text("Aucune photo")
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    TabView(selection: $selection) {
                        ForEach(photos.indices, id: \.self) { idx in
                            VStack(spacing: 12) {
                                // Photo + overlay
                                ZStack(alignment: .bottomLeading) {
                                    AsyncPhotoPagerView(photo: photos[idx])
                                        .frame(height: 410)
                                        .frame(maxWidth: .infinity)
                                        .clipped()

                                    VStack(alignment: .leading, spacing: 6) {
                                        if let desc = photos[idx].description, !desc.isEmpty {
                                            Text(desc)
                                                .font(.body)
                                                .foregroundColor(.white)
                                                .shadow(radius: 3)
                                        }

                                        if let livePhoto = viewModel.currentPhoto, livePhoto.id == photos[idx].id {
                                            LikeSection(
                                                photo: livePhoto,
                                                challengeId: livePhoto.challengeId ?? "",
                                                likeAction: { userId in
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
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.black.opacity(0.7), .clear]),
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                }
                                .frame(height: 410)
                                .clipShape(RoundedRectangle(cornerRadius: 20))

                                // Médailles
                                if let participant = getParticipant(photos[idx].authorUid) {
                                    MedalsSection(medals: participant.medals)
                                        .padding(.bottom, 6)
                                }

                                // Commentaires
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Divider().background(Color.white.opacity(0.3))
                                        ForEach(viewModel.comments) { comment in
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(comment.userName)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.white)
                                                Text(comment.content)
                                                    .font(.body)
                                                    .foregroundColor(.white.opacity(0.85))
                                            }
                                            .padding(.bottom, 4)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()

                                }
                                .frame(maxHeight: 200)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

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
                }
            }

            CommentsInputBar(
                commentText: $commentText,
                isTextFieldFocused: $isTextFieldFocused,
                onSubmit: sendComment
            )
            .padding(.horizontal)
            //TODO: POURQOI -300 fonctionne... a voir si meme rendu sur tout les tel
            .padding(.bottom, keyboard.keyboardHeight == 0 ? 16 : keyboard.keyboardHeight - 300)
            .animation(.easeOut(duration: 0.25), value: keyboard.keyboardHeight)
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

    private func sendComment() {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let challengeId = currentPhoto?.challengeId, let photoId = currentPhoto?.id {
            viewModel.addComment(trimmed, challengeId: challengeId, photoId: photoId, challengeTitle: challengeTitle)
            commentText = ""
        }
        isTextFieldFocused = false
    }

    private func listenToCurrentPhoto() {
        guard !photos.isEmpty, selection < photos.count,
              let challengeId = photos[selection].challengeId,
              let photoId = photos[selection].id else { return }

        viewModel.listenToPhotoRealtime(challengeId: challengeId, photoId: photoId)
        viewModel.listenToComments(challengeId: challengeId, photoId: photoId)
    }
}


struct CommentsInputBar: View {
    @Binding var commentText: String
    @FocusState.Binding var isTextFieldFocused: Bool

    var onSubmit: () -> Void

    var body: some View {
        HStack {
            TextField("Ajouter un commentaire...", text: $commentText)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .submitLabel(.send)
                .onSubmit {
                    onSubmit()
                }

            Button(action: onSubmit) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.accentColor)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
