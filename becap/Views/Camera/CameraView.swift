//
//  CameraView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel = CameraViewModel()

    @State private var showCamera: Bool = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                header
                infoCard
                photoCard
                uploadPhotoButton
            }
            .frame(maxWidth: .infinity)
            .padding([.horizontal, .bottom])
            .padding(.top, 2)
        }
       // .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
        .background(LinearGradient.petrolToSky.ignoresSafeArea())
        .navigationTitle("Prendre une photo")
        .sheet(isPresented: $showCamera) {
            CameraCaptureView(image: $viewModel.selectedImage)
        }
        .overlay(content: {
            if viewModel.toast.isShown {
                toastView
            }
        })
    }

    private var header: some View {
        Text("Nouvelle photo")
            .font(.largeTitle.bold())
            .foregroundColor(.white)
            .padding(.top, 12)
            .shadow(radius: 8)
    }

    private var infoCard: some View {
        GroupBox {
            HStack(alignment: .center, spacing: 12) {
                Text("Défi").font(.subheadline.bold())
                Picker("Défi", selection: $viewModel.selectedChallenge) {
                    ForEach(viewModel.challenges) { challenge in
                        Text(challenge.title).tag(Optional(challenge))
                    }
                }
                .pickerStyle(.menu)
                .modifier(ShakeEffect(animatableData: viewModel.shakeChallenge ? 1 : 0))
            }
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.13), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var photoCard: some View {
        GroupBox {
            VStack(spacing: 18) {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 210)
                        .cornerRadius(18)
                        .shadow(radius: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.accentColor.opacity(0.4), lineWidth: 2)
                        )
                        .padding(.bottom, 2)
                        .modifier(ShakeEffect(animatableData: viewModel.shakeImage ? 1 : 0))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 130)
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 45))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    .padding(.bottom, 2)
                    .modifier(ShakeEffect(animatableData: viewModel.shakeImage ? 1 : 0))
                }

                takePhotoButton

                TextField("Description (optionnelle)", text: $viewModel.descriptionText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 4)
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.13), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var takePhotoButton: some View {
        Button {
            showCamera = true
        } label: {
            Label(viewModel.takePhotoButtonLabel, systemImage: "camera.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    AnyView(Color.clear.background(.thinMaterial))
                )
                .foregroundColor(.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.black.opacity(0.11), radius: 7, x: 0, y: 3)
        }
    }

    @ViewBuilder
    private var uploadPhotoButton: some View {
        Button {
            viewModel.uploadPhoto()
        } label: {
            if viewModel.isUploadingPhoto {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Label("Enregistrer la photo", systemImage: "square.and.arrow.down.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.clear.background(.thinMaterial))
                    .foregroundColor(.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.black.opacity(0.13), radius: 8, x: 0, y: 3)
            }
        }
        .padding(.top, 2)
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
                Button(action: {
                    viewModel.closeToast()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                .padding(.trailing, 6)
                Spacer()
            }
            .padding(.bottom, 44)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(10)
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat = 0
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 10 * sin(animatableData * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
