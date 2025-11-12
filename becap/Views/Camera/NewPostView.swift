//
//  NewPostView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct NewPostView: View {
    @StateObject private var viewModel: NewPostViewModel = NewPostViewModel()

    @State private var showCamera = false
    @State private var showMediaPreview = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection

                    GlassCard {
                        challengePickerSection
                    }

                    GlassCard {
                        mediaSection
                    }

                    GlassCard {
                        uploadSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 70 + 16)
            }
            .background(LinearGradient.petrolToSky.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showCamera) {
            CustomCameraView() { media in
                viewModel.updateSelectedMedia(media)
            }
        }
        .overlay(alignment: .top) {
            if viewModel.toast.isShown {
                ToastView(message: viewModel.toast.message,
                          type: viewModel.toast.type)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Spacer()
            Text("Nouveau Post")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            Spacer()
        }
    }

    private var challengePickerSection: some View {
        HStack(spacing: 12) {
            Text("Défi:").font(.subheadline.bold())
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .textCase(.uppercase)
                .foregroundColor(.white)
            Spacer()
            Picker("", selection: $viewModel.selectedChallenge) {
                ForEach(viewModel.challenges) { challenge in
                    Text(challenge.title).tag(Optional(challenge))
                }
            }
            .pickerStyle(.segmented)
            .modifier(ShakeEffect(animatableData: viewModel.shakeChallenge ? 1 : 0))
        }
        .padding(4)
    }

    private var uploadSection: some View {
        Button {
            viewModel.uploadMedia()
        } label: {
            HStack {
                if viewModel.isUploadingPost {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Partager le post")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .textCase(.uppercase)
                        .foregroundColor(.white)

                }
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
            .padding(.horizontal, 20 )
        }
        .buttonStyle(.plain)
        .opacity(viewModel.isUploadingPost ? 0.8 : 1.0)
        .padding(4)
    }

    private var mediaSection: some View {
        VStack(spacing: 20) {
            if let media = viewModel.selectedMedia {
                VStack {
                    Button(role: .destructive) {
                        viewModel.eraseMedia()
                    } label: {
                        Label("Supprimer le média enregistré", systemImage: "trash")
                            .font(.system(.body, design: .rounded).weight(.medium))
                    }
                    .frame(maxWidth: .infinity, minHeight: 35)
                    .background(.thinMaterial)
                    .cornerRadius(14)
                    .shadow(color: Color.blue.opacity(0.38), radius: 10, x: 0, y: 3)

                    HStack(spacing: .zero) {
                        switch media {
                        case .image(let uiImage):
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(14)
                                .shadow(radius: 6)
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.accentColor.opacity(0.5), lineWidth: 1))
                                .modifier(ShakeEffect(animatableData: viewModel.shakeImage ? 1 : 0))
                        case .video(let data):
                            if let thumbnailImage = data.thumbnailImage {
                                ZStack {
                                    Image(uiImage: thumbnailImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                        .cornerRadius(12)

                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                .padding()
                                .shadow(radius: 6)
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
                                CustomVideoPlayer(videoURL: data.url)
                                    .ignoresSafeArea()
                            }

                            Text("Fermer")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.7))
                                .cornerRadius(14)
                                .padding(.horizontal, 32)
                                .padding(.bottom, 40)
                                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                                .onTapGesture { showMediaPreview = false }
                        }
                        .interactiveDismissDisabled(true)
                    }
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(height: 170)
            }

            HStack(spacing: 10) {
                Image(systemName: "camera")
                    .font(.system(size: 23, weight: .medium))
                    .foregroundColor(.white)
                Text(viewModel.takePhotoButtonLabel)
                    .font(.system(.body, design: .rounded).weight(.heavy))
                    .textCase(.uppercase)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(.thinMaterial)
            .cornerRadius(14)
            .shadow(color: Color.blue.opacity(0.38), radius: 10, x: 0, y: 3)
            .onTapGesture { showCamera = true }

            TextField("Description (optionnelle)", text: $viewModel.descriptionText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(4)
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
                    .onTapGesture { viewModel.closeToast() }
                    .padding(.trailing, 6)

                Spacer()
            }
        }
    }
}
