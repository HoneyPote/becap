//
//  CalendarPhotoPagerView.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//

import SwiftUI

struct CalendarPhotoPagerView: View {
    @StateObject private var viewModel: PhotoPagerViewModel
    @StateObject private var keyboard = KeyboardResponder()

    @FocusState private var isTextFieldFocused: Bool

    @State private var commentText = ""

    let getParticipant: (String) -> Participant?
    let onDelete: (ChallengePhoto) -> Void
    let onClose: () -> Void

    init(photos: [ChallengePhoto],
         startIndex: Int = 0,
         getParticipant: @escaping (String) -> Participant?,
         onDelete: @escaping (ChallengePhoto) -> Void,
         onClose: @escaping () -> Void) {
        self.getParticipant = getParticipant
        self.onDelete = onDelete
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: PhotoPagerViewModel(photos: photos, selectedPhotoIndex: startIndex))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient.petrolToSky.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 26)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 6)

                // Main content
                if viewModel.allPhotos.isEmpty {
                    Spacer()
                    Text("Aucune photo")
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    TabView(selection: $viewModel.selectedPhotoIndex) {
                        ForEach(viewModel.allPhotos.indices, id: \.self) { idx in
                            VStack(spacing: 12) {
                                // Photo + overlay
                                photoView(for: viewModel.currentPhoto)
                                    .frame(height: 410)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))

                                // Médailles
                                if let participant = getParticipant(viewModel.currentPhoto.authorUid) {
                                    MedalsSection(medals: participant.medals)
                                        .padding(.bottom, 6)
                                }

                                // Commentaires
                                commentSection
                                    .frame(maxHeight: 200)
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                // Date
                                Text(viewModel.photoFormatedDate)
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

            // TODO: Y'a un truc à repenser ici
            CommentsInputBar(commentText: $commentText, isTextFieldFocused: $isTextFieldFocused, onSubmit: sendComment)
                .padding(.horizontal)
            // TODO: POURQOI -300 fonctionne... a voir si meme rendu sur tout les tel
                .padding(.bottom, keyboard.keyboardHeight == 0 ? 16 : keyboard.keyboardHeight - 300)
                .animation(.easeOut(duration: 0.25), value: keyboard.keyboardHeight)
        }
        .onAppear {
            viewModel.listenCurrentPhoto()
        }
    }

    private var header: some View {
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

            Text(viewModel.currentPhoto.authorName)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            if viewModel.canDeletePhoto() {
                Button(role: .destructive) {
                    onDelete(viewModel.currentPhoto)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
            }
        }
    }

    private func photoView(for photo: ChallengePhoto) -> some View {
        ZStack(alignment: .bottomLeading) {
            AsyncPhotoPagerView(photo: photo)
                .frame(height: 410)
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: 6) {
                if let desc = photo.description, !desc.isEmpty {
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                }

                LikeSection(photo: photo,
                            likeAction: { userId in
                    viewModel.like()
                },
                            unlikeAction: { userId in
                    viewModel.unlike()
                },
                            getParticipant: getParticipant)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), .clear]),
                               startPoint: .bottom,
                               endPoint: .top)
            )
        }
    }

    private var commentSection: some View {
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
    }

    private func sendComment() {
        viewModel.addComment(content: commentText)
        commentText = ""
        isTextFieldFocused = false
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
                .onSubmit { onSubmit() }

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
