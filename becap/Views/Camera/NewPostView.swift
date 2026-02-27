//
//  NewPostView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI
import UIKit
import AVKit
import AVFoundation

struct NewPostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NewPostViewModel

    @State private var showMediaPreview = false

    let onCameraButtonClick: () -> Void

    init(challenge: Challenge, rawMedia: ChallengeRawMedia?, onCameraButtonClick: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: NewPostViewModel(challenge: challenge, rawMedia: rawMedia))
        self.onCameraButtonClick = onCameraButtonClick
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection

                GlassCard {
                    challengePickerSection
                }

                GlassCard {
                    mediaSection
                }
                .padding(.top, -15)

                uploadSection
                    .padding(.top, -15)
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
        }
        .background(
            ZStack {
                // Filler: covers edges at any ratio
                Image("iphone_wallpaper_cliff")
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 12)
                    .ignoresSafeArea()

                // Sharp layer, slightly zoomed out
                Image("iphone_wallpaper_cliff")
                    .resizable()
                    .scaledToFill()
                    .offset(x: -25) // 0.85–0.95 depending on taste
                    .ignoresSafeArea()

                // Global dark veil
                Color.black.opacity(0.15).ignoresSafeArea()
            }
                .allowsHitTesting(false)
        )
        .overlay(alignment: .top) {
            VStack(spacing: 10) {
                if viewModel.toast.isShown {
                    ToastView(message: viewModel.toast.message,
                              type: viewModel.toast.type)
                }

                if let durationLabel = viewModel.uploadDurationLabel {
                    uploadProgressAlert(durationLabel: durationLabel)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.top, 6)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Nouveau Post")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Partage ton énergie et inspire ton équipe en quelques secondes.")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(.white.opacity(0.75))
            }

            Divider()
                .background(Color.white.opacity(0.35))
        }
        .padding(.horizontal, 4)
    }

    private var challengePickerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Défi selectionné")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .textCase(.uppercase)
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.currentChallenge.title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)

                    if let categoryName = viewModel.currentChallenge.category?.displayName {
                        Text(categoryName)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .padding(4)
    }

    private var uploadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                viewModel.uploadMedia() { hasUploaded in
                    if hasUploaded {
                        dismiss()
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    if viewModel.isUploadingPost {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20, weight: .semibold))
                    }

                    Text(viewModel.uploadButtonLabel)
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .textCase(.uppercase)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.92, green: 0.86, blue: 0.72),  // beige clair foncé
                                    Color(red: 0.88, green: 0.78, blue: 0.60)   // beige chaud plus profond
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(viewModel.isUploadingPost || viewModel.selectedMedia == nil)
            .opacity((viewModel.isUploadingPost || viewModel.selectedMedia == nil) ? 0.85 : 1.0)

            Button {
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Annuler la publication")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .textCase(.uppercase)
                }
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(viewModel.isUploadingPost || viewModel.selectedMedia == nil)
            .opacity((viewModel.isUploadingPost || viewModel.selectedMedia == nil) ? 0.85 : 1.0)
        }
        .padding(4)
    }

    private var mediaSection: some View {
        VStack(spacing: 20) {
            if let media = viewModel.selectedMedia {
                VStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.eraseMedia()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Supprimer le média enregistré")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.red.opacity(0.18))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.96))
                    .padding(.bottom, 4)

                    HStack(spacing: .zero) {
                        switch media {
                        case .image(let uiImage):
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 220)
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 12)
                                .overlay(RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1.2))
                                .modifier(ShakeEffect(animatableData: viewModel.shakeImage ? 1 : 0))
                        case .video(let data):
                            if let thumbnailImage = data.thumbnailImage {
                                ZStack {
                                    Image(uiImage: thumbnailImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 220)
                                        .cornerRadius(18)

                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Color.black.opacity(0.15))
                                )
                                .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 16)
                            }
                        }
                    }
                    .onTapGesture {
                        showMediaPreview = true
                    }
                    .sheet(isPresented: $showMediaPreview) {
                        ZStack(alignment: .bottom) {
                            if case .image(let uiImage) = media {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .ignoresSafeArea()
                            } else if case .video(let data) = media {
                                CustomVideoPlayer(videoURL: data.url, configuration: PlayerConfiguration.preview)
                                    .ignoresSafeArea()
                            }

                            Button {
                                showMediaPreview = false
                            } label: {
                                Text("Fermer")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black.opacity(0.55))
                                    .cornerRadius(16)
                                    .padding(.horizontal, 32)
                                    .padding(.bottom, 40)
                                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                            }
                            .buttonStyle(PressableButtonStyle(scale: 0.95))
                        }
                        .interactiveDismissDisabled(true)
                    }
                }
            } else {
                CaptureButton {
                    onCameraButtonClick()
                }
            }

            TextField("Description (optionnelle)", text: $viewModel.descriptionText)
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
                .font(.system(.body, design: .rounded))
        }
        .padding(4)
    }

    private func uploadProgressAlert(durationLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: viewModel.isUploadingPost ? "arrow.up.circle.fill" : "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(viewModel.isUploadingPost ? .white : Color.green.opacity(0.95))

                Text(viewModel.isUploadingPost ? "Publication en cours" : "Publication prête")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(.white.opacity(0.95))

                Spacer()

                Text("\(Int(viewModel.uploadProgress * 100))%")
                    .font(.system(.caption, design: .rounded).weight(.heavy))
                    .foregroundColor(.white)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.2))

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.43, green: 0.76, blue: 0.98), Color(red: 0.21, green: 0.44, blue: 0.69)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, min(1, viewModel.uploadProgress)) * geometry.size.width)
                        .animation(.easeOut(duration: 0.2), value: viewModel.uploadProgress)
                }
            }
            .frame(height: 7)

            HStack {
                Text(durationLabel)
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundColor(.white.opacity(0.82))

                Spacer()

                Text(viewModel.isUploadingPost ? "Envoi sécurisé" : "Terminé")
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundColor(.white.opacity(0.78))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.29, green: 0.58, blue: 0.84).opacity(0.92),
                            Color(red: 0.21, green: 0.44, blue: 0.69).opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.28), radius: 10, x: 0, y: 5)
    }

    private var toastView: some View {
        VStack {
            Spacer()

            HStack(spacing: 8) {
                Spacer()
                Text(viewModel.toast.message)
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 22)
                    .background(viewModel.toast.type == .success ? Color.green.opacity(0.95) : Color.red.opacity(0.95))
                    .cornerRadius(28)
                    .shadow(radius: 16)

                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                    .onTapGesture { viewModel.closeToast(); dismiss() }
                    .padding(.trailing, 6)

                Spacer()
            }
        }
    }
}

struct ChallengeChip: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .layoutPriority(1)

                if let subtitle {
                    Text(subtitle.uppercased())
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.18))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(minWidth: 160, alignment: .leading)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(isSelected ? 0.0 : 0.12), lineWidth: 1)
        )
        .scaleEffect(isSelected ? 1.03 : 1)
    }

    // MARK: - Background depending on selection
    private var background: some View {
        Group {
            if isSelected {
                // 🌕 Dégradé beige (sélectionné)
                LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.86, blue: 0.72),  // beige clair foncé
                        Color(red: 0.88, green: 0.78, blue: 0.60)   // beige chaud plus profond
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                // 🌤️ Bleu ciel (non sélectionné)
                LinearGradient(
                    colors: [
                        Color(red: 0.29, green: 0.58, blue: 0.84), // Bleu clair
                        Color(red: 0.21, green: 0.44, blue: 0.69)  // Bleu foncé
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

private struct CaptureButton: View {
    let action: () -> Void

    private let cornerRadius: CGFloat = 20

    @StateObject private var videoController = LoopingPlayerController(
        resourceCandidates: [
            "dégradéBleu",
            "dégradéBleu"
        ],
        fileExtension: "mp4"
    )

    var body: some View {
        Button(action: action) {
            ZStack {
                LoopingVideoBackground(player: videoController.player)
                content
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.22), radius: 18, x: 0, y: 14)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.965))
        .onAppear { videoController.play() }
        .onDisappear { videoController.pause() }
    }

    private var content: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.aperture")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.white)

            Text("Prendre une photo ou vidéo")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Appuie pour capturer ton moment inspirant")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 18)
    }
}

private struct LoopingVideoBackground: View {
    let player: AVQueuePlayer?

    var body: some View {
        Group {
            if let player {
                LoopingPlayerView(player: player)
                    .overlay(Color.black.opacity(0.25))
            } else {
                LinearGradient(
                    colors: [Color(hex: "5A5AF7"), Color(hex: "8E54E9")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private final class LoopingPlayerController: ObservableObject {
    let player: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    init(resourceCandidates: [String], fileExtension: String) {
        var selectedURL: URL?
        for name in resourceCandidates {
            if let url = Bundle.main.url(forResource: name, withExtension: fileExtension) {
                selectedURL = url
                break
            }
        }

        if let selectedURL {
            let asset = AVAsset(url: selectedURL)
            let item = AVPlayerItem(asset: asset)
            let queuePlayer = AVQueuePlayer()
            queuePlayer.actionAtItemEnd = .none
            queuePlayer.isMuted = true
            queuePlayer.volume = 0

            self.player = queuePlayer
            self.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        } else {
            self.player = nil
        }
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
        player?.seek(to: .zero)
    }
}

private struct LoopingPlayerView: UIViewRepresentable {
    let player: AVQueuePlayer

    func makeUIView(context: Context) -> zPlayerContainerView {
        let view = zPlayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: zPlayerContainerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }

    static func dismantleUIView(_ uiView: zPlayerContainerView, coordinator: ()) {
        uiView.playerLayer.player = nil
    }
}

private final class zPlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer {
        // swiftlint:disable:next force_cast
        return layer as! AVPlayerLayer
    }
}
