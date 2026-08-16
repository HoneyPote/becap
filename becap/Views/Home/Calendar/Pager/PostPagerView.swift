//
//  PostPagerView.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//

import SwiftUI

struct PostPagerView: View {
    @StateObject private var viewModel: PostPagerViewModel
    @StateObject private var keyboard = KeyboardResponder()

    @FocusState private var isTextFieldFocused: Bool

    @State private var playerConfig: PlayerConfiguration? = .postPager
    @State private var commentText: String = ""
    @State private var commentSectionIsShown: Bool = false
	@State private var isVideoReady = false
    @State private var pendingJokerAction: JokerAction?
    @State private var showDeleteAlert = false

    let getParticipant: (String) -> ParticipantUIModel?
    let onDelete: (String) -> Void
    let onClose: () -> Void

    private enum JokerAction {
        case vote
        case declare
    }

    init(posts: [ChallengePost],
         startIndex: Int = 0,
         challenge: any ChallengeRepresentable,
         getParticipant: @escaping (String) -> ParticipantUIModel?,
         onDelete: @escaping (String) -> Void,
         onClose: @escaping () -> Void) {
        self.getParticipant = getParticipant
        self.onDelete = onDelete
        self.onClose = onClose

        _viewModel = StateObject(wrappedValue: PostPagerViewModel(posts: posts,
                                                                  selectedPostIndex: startIndex,
                                                                  challenge: challenge))
    }

    var body: some View {
        ZStack {
            detailBackground

            VStack(spacing: .zero) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)

                if viewModel.postViewModels.isEmpty {
                    Spacer()
                    Text("Aucun post")
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    TabView(selection: $viewModel.selectedIndex) {
                        ForEach(Array(viewModel.postViewModels.enumerated()), id: \.element.id) { idx, postVM in
                            ScrollView(showsIndicators: false) {
                                currentPostContent(postVM: postVM)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 46)
                            }
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: commentSectionIsShown)
                                .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
        }
        .interactiveDismissDisabled()
        .onChange(of: viewModel.selectedIndex) { _ in
            commentSectionIsShown = false
            resetCommentTextfield()
        }
        .alert(isPresented: Binding<Bool>(
            get: { pendingJokerAction != nil },
            set: { if !$0 { pendingJokerAction = nil } }
        )) {
            let action = pendingJokerAction ?? .vote

            switch action {
            case .declare:
                return Alert(title: Text("Utiliser un joker"),
                             message: Text("Confirmer que cette journée consomme un de vos jokers ?"),
                             primaryButton: .default(Text("Confirmer")) {
                                viewModel.toggleJoker()
                                pendingJokerAction = nil
                             },
                             secondaryButton: .cancel())
            case .vote:
                return Alert(title: Text("Voter pour un joker"),
                             message: Text("Confirmer que ce post doit utiliser un joker ?"),
                             primaryButton: .default(Text("Voter")) {
                                viewModel.toggleJoker()
                                pendingJokerAction = nil
                             },
                             secondaryButton: .cancel())
            }
        }
    }

    private func currentPostContent(postVM: PostViewModel) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Label(viewModel.postFormattedDate, systemImage: "calendar")
                    .lineLimit(1)

                Spacer()

                Text("\(viewModel.selectedIndex + 1) / \(viewModel.postViewModels.count)")
                    .monospacedDigit()
            }
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(.white.opacity(0.62))

            imageView(for: postVM)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.32), radius: 24, x: 0, y: 14)

            if let score = postVM.post.aiScore {
                BecapScoreCard(score: score, compact: true)
            }

            if !commentSectionIsShown {
                if let participant = getParticipant(postVM.post.authorUid) {
                    let challengeMedals = participant.userMedals.filter { $0.challengeId == viewModel.challenge.id }
                    MedalsSection(medals: challengeMedals)
                        .padding(.bottom, 6)
                }

                Button {
                    withAnimation { commentSectionIsShown = true }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundStyle(Color(red: 0.43, green: 0.82, blue: 0.77))
                        Text(postVM.comments.isEmpty ? "Démarrer la discussion" : "Voir les commentaires")
                            .fontWeight(.bold)
                        Spacer()
                        if !postVM.comments.isEmpty {
                            Text("\(postVM.comments.count)")
                                .font(.caption.monospacedDigit().weight(.heavy))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.1), in: Capsule())
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }

            commentSection(postVM: postVM)
                .frame(height: commentSectionIsShown ? 390 : 0)
                .opacity(commentSectionIsShown ? 1 : 0)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button(action: onClose) {
                headerIcon("xmark")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.selectedPostVM.post.authorName)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(viewModel.challenge.title)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            if viewModel.canDeletePost {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    headerIcon("trash", tint: Color(red: 1, green: 0.43, blue: 0.43))
                }
                .alert("Êtes-vous sûr de vouloir supprimer ce post ?", isPresented: $showDeleteAlert) {
                    Button("Supprimer", role: .destructive) {
                        viewModel.deletePost { isDeleted, deletedPost in
                            guard isDeleted, let deletedPostId = deletedPost?.id else { return }
                            onDelete(deletedPostId)
                        }
                    }

                    Button("Annuler", role: .cancel) { }
                } message: {
                    Text("Cette action est irréversible.")
                }
            } else {
                Color.clear.frame(width: 42, height: 42)
            }
        }
    }

    private func headerIcon(_ name: String, tint: Color = .white) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(tint)
            .frame(width: 42, height: 42)
            .background(Color.white.opacity(0.08), in: Circle())
            .overlay { Circle().stroke(Color.white.opacity(0.12), lineWidth: 1) }
    }

    private var detailBackground: some View {
        ZStack {
            Color(red: 0.035, green: 0.055, blue: 0.085)
            LinearGradient(colors: [
                Color(red: 0.04, green: 0.13, blue: 0.16).opacity(0.9),
                Color(red: 0.035, green: 0.055, blue: 0.085),
                Color(red: 0.08, green: 0.055, blue: 0.12).opacity(0.8)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)

            Circle()
                .fill(Color(red: 0.16, green: 0.56, blue: 0.54).opacity(0.16))
                .frame(width: 330, height: 330)
                .blur(radius: 80)
                .offset(x: 170, y: -300)

            Circle()
                .fill(Color(red: 0.35, green: 0.19, blue: 0.48).opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: -170, y: 350)
        }
        .ignoresSafeArea()
    }
}

// MARK: Image section
extension PostPagerView {
    private func imageView(for postVM: PostViewModel) -> some View {
        ZStack(alignment: .bottom) {
            Group {
                if case .image(let url) = postVM.post.media, let imageUrl = URL(string: url) {
                    AsyncCachedImage(url: imageUrl)
                } else if case .video(let data) = postVM.post.media, let videoUrl = URL(string: data.videoURL) {
                    CustomVideoPlayer(videoURL: videoUrl,
                                      thumbnailURL: URL(string: data.thumbnailURL ?? ""),
                                      configuration: commentSectionIsShown ? .postPagerComments : .postPager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 500)
            .background(Color.black.opacity(0.28))

            if !commentSectionIsShown {
                VStack(alignment: .leading, spacing: 6) {
                    if let desc = postVM.post.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    LikeSection(postLikes: postVM.likes,
                                likeAction: { _ in viewModel.likeAction() },
                                unlikeAction: { _ in viewModel.unlikeAction() },
                                getParticipant: getParticipant)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.82), .clear]),
                                   startPoint: .bottom,
                                   endPoint: .top)
                )
            }
        }
        .overlay(alignment: .bottomTrailing) {
            jokerBadge(for: viewModel.selectedJokerState)
                .padding(20)
        }
    }

    private func jokerBadge(for state: PostJokerState) -> some View {
        Button(action: { handleJokerTap(for: state) }) {
            JokerIconView(size: 40, isDimmed: state.isConfirmed || viewModel.hasCurrentUserVoted)
                .overlay(alignment: .topTrailing) {
                    voteBubble(for: state.voters.count)
                }
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canToggleJokerVote)
    }

    private func voteBubble(for count: Int) -> some View {
        Text("\(count)")
            .font(.caption2.bold())
            .foregroundColor(count > 0 ? .white : .black.opacity(0.75))
            .padding(6)
            .background((count > 0 ? Color.pink.opacity(0.85) : Color.white.opacity(0.35)))
            .clipShape(Circle())
            .offset(x: 8, y: -8)
    }

    private func handleJokerTap(for state: PostJokerState) {
        guard !state.isConfirmed else { return }

        if viewModel.canDeclareJoker {
            pendingJokerAction = .declare
        } else if viewModel.canToggleJokerVote {
            pendingJokerAction = .vote
        }
    }
}

// MARK: Comments section
extension PostPagerView {
    private func commentSection(postVM: PostViewModel) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Discussion")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    Text("\(postVM.comments.count) commentaire\(postVM.comments.count > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.48))
                }

                Spacer()

                Button {
                    withAnimation {
                        commentSectionIsShown = false
                        resetCommentTextfield()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider().overlay(Color.white.opacity(0.08))

            if postVM.comments.isEmpty {
                VStack(spacing: 9) {
                    Image(systemName: "bubble.left")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.35))
                    Text("Soyez le premier à commenter")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        commentList(comments: postVM.comments)
                    }
                    .padding(16)
                }
            }

            CommentsInputBar(commentText: $commentText,
                             isTextFieldFocused: $isTextFieldFocused,
                             onSubmit: { sendComment(postVM: postVM) })
                .animation(.easeOut(duration: 0.25), value: keyboard.keyboardHeight)
        }
        .background(Color(red: 0.055, green: 0.08, blue: 0.11).opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        }
    }

    private func commentList(comments: [PostCommentModel] = []) -> some View {
        ForEach(comments) { comment in
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Text(comment.userName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    Text(viewModel.buildCommentFormattedDate(date: comment.timestamp))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }

                Text(comment.content)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.82))
            }
            .padding(12)
            .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func sendComment(postVM: PostViewModel) {
        postVM.addComment(post: postVM.post, content: commentText)
        resetCommentTextfield()
    }

    private func resetCommentTextfield() {
        commentText = ""
        isTextFieldFocused = false
    }
}

struct CommentsInputBar: View {
    @Binding var commentText: String
    @FocusState.Binding var isTextFieldFocused: Bool

    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("Ajouter un commentaire...", text: $commentText)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Color.white.opacity(0.07), in: Capsule())
                .overlay { Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1) }
                .foregroundColor(.white)
                .focused($isTextFieldFocused)
                .submitLabel(.send)
                .onSubmit { onSubmit() }

            if isTextFieldFocused {
                Button(action: onSubmit) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color(red: 0.24, green: 0.62, blue: 0.58))
                        .clipShape(Circle())
                }
                .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.12))
    }
}
