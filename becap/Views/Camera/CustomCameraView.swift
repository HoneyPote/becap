//
//  CustomCameraView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI
import AVFoundation

struct CustomCameraView: View {
    @StateObject private var viewModel = CustomCameraViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var isCaptureButtonPressed: Bool = false

    var onCapture: (ChallengeRawMedia) -> Void

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
        .overlay(alignment: .topLeading) {
            if !viewModel.isRecordingVideo {
                HStack {
                    Text("Annuler")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Capsule())
                        .onTapGesture { dismiss() }
                }
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
                CustomVideoPlayer(videoURL: data.url, launchOnAppear: true)
                    .ignoresSafeArea()
            }

            HStack {
                Text("Enregistrer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.7))
                    .cornerRadius(14)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .onTapGesture {
                        onCapture(media)
                        dismiss()
                    }

                Text("Reprendre")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.7))
                    .cornerRadius(14)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.retakeMedia()
                        }
                    }
            }
        }
    }

    var mediaCaptureControls: some View {
        VStack {
            HStack {
                Spacer()

                if viewModel.isRecordingVideo {
                    Text(viewModel.videoRecordingTimer)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                        .padding(.top, 20)
                        .transition(.opacity)
                }

                Spacer()

                if viewModel.showFlashButton {
                    Image(systemName: viewModel.flashIconName)
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                        .onTapGesture { viewModel.toggleFlash() }
                }
            }
            .padding()

            Spacer()

            HStack(alignment: .center, spacing: .zero) {
                Spacer()

                ZStack {
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
}

struct PulsatingEffect: ViewModifier {
    @State private var animate = false

    var isActive: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(animate ? 1.15 : 0.9)
            .opacity(animate ? 0.9 : 0.5)
            .animation(isActive ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: animate)
            .onAppear { animate = true }
            .onDisappear { animate = false }
    }
}
