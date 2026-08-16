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
        ZStack(alignment: .bottom) {
            LinearGradient.petrolToSky.ignoresSafeArea()

            VStack(spacing: .zero) {
                header
                    .padding(.top, 26)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 6)

                if viewModel.postViewModels.isEmpty {
                    Spacer()
                    Text("Aucun post")
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    TabView(selection: $viewModel.selectedIndex) {
                        ForEach(Array(viewModel.postViewModels.enumerated()), id: \.element.id) { idx, postVM in
                            currentPostContent(postVM: postVM)
                                .padding(.bottom, 40)
                                .padding(.horizontal)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: commentSectionIsShown)
                                .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                }
            }
        }
        .interactiveDismissDisabled()
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
        VStack(spacing: 12) {
            Text(viewModel.postFormattedDate)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 2)

            imageView(for: postVM)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            if let score = postVM.post.aiScore {
                BecapScoreCard(score: score, compact: true)
            }

            if !commentSectionIsShown {
                if let participant = getParticipant(postVM.post.authorUid) {
                    let challengeMedals = participant.userMedals.filter { $0.challengeId == viewModel.challenge.id }
                    MedalsSection(medals: challengeMedals)
                        .padding(.bottom, 6)
                }

                HStack(spacing: 8) {
                    Image(systemName: "bubble.right.fill")

                    Text("Voir les commentaires")
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .foregroundColor(.white)
                .background(
                    LinearGradient(colors: [Color.blue, Color.cyan],
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                .onTapGesture {
                    withAnimation {
                        commentSectionIsShown = true
                    }
                }
            }

            commentSection(postVM: postVM)
                .frame(maxHeight: commentSectionIsShown ? 600 : 0)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .opacity(commentSectionIsShown ? 1 : 0)
                .offset(y: commentSectionIsShown ? 0 : 300)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "xmark")
                .foregroundColor(.white)
                .font(.title2.bold())
                .padding(8)
                .background(Color.black.opacity(0.22))
                .clipShape(Circle())
                .onTapGesture { onClose() }

            Spacer()

            Text(viewModel.selectedPostVM.post.authorName)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            if viewModel.canDeletePost {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(.thinMaterial)
                        .clipShape(Circle())
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
            }
        }
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
            .frame(maxWidth: commentSectionIsShown ? 150 : .infinity, maxHeight: 490)

            if !commentSectionIsShown {
                VStack(alignment: .leading, spacing: 6) {
                    if let desc = postVM.post.description, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                    }

                    LikeSection(postLikes: postVM.likes,
                                likeAction: { _ in viewModel.likeAction() },
                                unlikeAction: { _ in viewModel.unlikeAction() },
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

            if commentSectionIsShown {
                Rectangle()
                    .foregroundColor(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            commentSectionIsShown = false
                            resetCommentTextfield()
                        }
                    }
                    .frame(maxWidth: commentSectionIsShown ? 150 : .infinity, maxHeight: 490)
                    .allowsHitTesting(true)
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
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    commentList(comments: postVM.comments)

                    Divider().background(Color.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .padding(.bottom, 65)
            }

            CommentsInputBar(commentText: $commentText,
                             isTextFieldFocused: $isTextFieldFocused,
                             onSubmit: { sendComment(postVM: postVM) })
            .frame(maxWidth: .infinity)
            .animation(.easeOut(duration: 0.25), value: keyboard.keyboardHeight)
        }
    }

    private func commentList(comments: [PostCommentModel] = []) -> some View {
        ForEach(comments) { comment in
            VStack(alignment: .leading, spacing: 2) {
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
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.bottom, 4)
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
        HStack {
            TextField("Ajouter un commentaire...", text: $commentText)
                .padding(12)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
                .foregroundColor(.white)
                .focused($isTextFieldFocused)
                .submitLabel(.send)
                .onSubmit { onSubmit() }

            if isTextFieldFocused {
                Button(action: onSubmit) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 2)
    }
}
