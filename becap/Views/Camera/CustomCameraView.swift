//
//  CustomCameraView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI
import AVFoundation

struct CustomCameraView: View {
    @StateObject private var viewModel: CustomCameraViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isCaptureButtonPressed: Bool = false
    @State private var isTimelapseRingAnimating = false

    var onCapture: (ChallengeRawMedia) -> Void

    init(challenge: any ChallengeRepresentable,
         onCapture: @escaping (ChallengeRawMedia) -> Void) {
        self.onCapture = onCapture
        var becapData: BecapChallengeData? = nil
        if let challenge = challenge as? BecapChallenge {
            becapData = challenge.becapData
        }
        _viewModel = StateObject(wrappedValue: CustomCameraViewModel(becapData: becapData))
    }

    var body: some View {
        ZStack {
            CustomCameraPreview(viewModel: viewModel)
                .ignoresSafeArea()

            mediaCaptureControls
        }
        .onDisappear { viewModel.stopCaptureSession() }
        .overlay {
            if let media = viewModel.capturedMedia {
                mediaPreview(media: media)
                    .frame(maxHeight: .infinity)
                    .background(Color.black)
                    .transition(.opacity)
            }
        }
        .overlay {
            if viewModel.mode == .plank, viewModel.isProcessingTimelapse {
                timelapseProcessingOverlay
            }
        }
        .overlay {
            if viewModel.mode == .plank, let countdownValue = viewModel.prepCountdownValue {
                countdownOverlay(value: countdownValue)
            }
        }
        .overlay(alignment: .topLeading) {
            if !viewModel.isRecordingVideo {
                Button {
                    dismiss()
                } label: {
                    Text("Annuler")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(minWidth: 84, minHeight: BecapMetrics.minimumTapTarget)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Capsule())
                }
                .accessibilityHint("Ferme l’appareil photo")
                .padding()
            }
        }
        .interactiveDismissDisabled(true)
    }

    func mediaPreview(media: ChallengeRawMedia) -> some View {
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

            HStack(spacing: BecapMetrics.spacingM) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.resetCamera()
                    }
                } label: {
                    Label("Reprendre", systemImage: "arrow.counterclockwise")
                        .font(BecapTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.black.opacity(0.62))
                        .clipShape(RoundedRectangle(cornerRadius: BecapMetrics.controlRadius, style: .continuous))
                }
                .accessibilityHint("Supprime cette capture et rouvre l’appareil photo")

                Button {
                    viewModel.stopCaptureSession()
                    onCapture(media)
                } label: {
                    Label("Continuer", systemImage: "arrow.right")
                        .font(BecapTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(BecapColors.actionGradient)
                        .clipShape(RoundedRectangle(cornerRadius: BecapMetrics.controlRadius, style: .continuous))
                }
                .accessibilityHint("Utilise cette capture comme preuve")
            }
            .padding(.horizontal, BecapMetrics.spacingM)
            .padding(.bottom, BecapMetrics.spacingL)
        }
    }

    var mediaCaptureControls: some View {
        VStack {
            HStack {
                Spacer()

                if viewModel.isRecordingVideo {
                    VStack(spacing: 6) {
                        if viewModel.mode == .plank, !viewModel.isInPrepCountdown {
                            Text(viewModel.videoRecordingTimer)
                                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        } else if viewModel.mode != .plank {
                            Text(viewModel.videoRecordingTimer)
                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(.top, 20)
                    .transition(.opacity)
                }

                Spacer()

                if viewModel.showFlashButton {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.rotate")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                            .onTapGesture { viewModel.switchCamera() }

                        Image(systemName: viewModel.flashIconName)
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                            .onTapGesture { viewModel.toggleFlash() }
                    }
                }
            }
            .padding()

            Spacer()

            HStack(alignment: .center, spacing: .zero) {
                Spacer()

                ZStack {
                    if viewModel.mode == .plank, viewModel.isRecordingVideo {
                        Circle()
                            .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 6, dash: [10, 6]))
                            .frame(width: 112, height: 112)
                            .rotationEffect(.degrees(isTimelapseRingAnimating ? 360 : 0))
                            .animation(reduceMotion ? nil : .linear(duration: 1.6).repeatForever(autoreverses: false),
                                       value: isTimelapseRingAnimating)
                            .onAppear { isTimelapseRingAnimating = true }
                            .onDisappear { isTimelapseRingAnimating = false }
                    }

                    if viewModel.isRecordingVideo {
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 30)
                            .frame(width: 100, height: 100)
                            .modifier(PulsatingEffect(isActive: viewModel.isRecordingVideo))
                    }

                    Circle()
                        .fill(viewModel.isRecordingVideo ? Color.red : Color.white)
                        .frame(width: 80, height: 80)
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .opacity(isCaptureButtonPressed ? 0.3 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isCaptureButtonPressed)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isRecordingVideo)
                        .onTapGesture {
                            isCaptureButtonPressed = false
                            viewModel.onCaptureButtonTap()
                        }
                        .gesture(longPressGesture)
                        .accessibilityLabel(viewModel.isRecordingVideo ? "Arrêter l’enregistrement" : "Prendre une photo")
                        .accessibilityHint("Touchez pour une photo, maintenez pour une vidéo")
                        .accessibilityAddTraits(.isButton)

                    if viewModel.isRecordingVideo {
                        Image(systemName: viewModel.lockIconName)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(0.9)
                            .offset(x: -110)
                            .transition(.opacity.combined(with: .scale))
                            .scaleEffect(viewModel.isLockedRecording ? 1.2 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isLockedRecording)
                    }
                }

                Spacer()
            }

            if viewModel.mode == .plank, viewModel.isRecordingVideo {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("REC")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Text("Tiens jusqu’à la fin 💪")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, 20)
                .transition(.opacity)
            }
        }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .first(true):
                    isCaptureButtonPressed = true
                case .second(true, nil):
                    isCaptureButtonPressed = false
                    viewModel.manageLongPress()
                case .second(true, let drag?):
                    viewModel.manageLongPress(drag: drag)
                default:
                    break
                }
            }
            .onEnded { value in
                switch value {
                case .second(true, _):
                    viewModel.manageLongPress()
                default:
                    break
                }
            }
    }

    private var timelapseProcessingOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                Text("⏳ Création du timelapse…")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(Color.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func countdownOverlay(value: Int) -> some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            Text("\(value)")
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .foregroundColor(.green)
                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: value)
        }
    }
}

struct PulsatingEffect: ViewModifier {
    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var isActive: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(animate ? 1.15 : 0.9)
            .opacity(animate ? 0.9 : 0.5)
            .animation(isActive && !reduceMotion
                       ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                       : nil,
                       value: animate)
            .onAppear { animate = true }
            .onDisappear { animate = false }
    }

}
