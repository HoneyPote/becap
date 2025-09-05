//
//  CameraView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel = CameraViewModel()

    @State private var showCamera = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection

                    GlassCard {
                        pickerSection
                    }

                    GlassCard {
                        photoSection
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
            CameraCaptureView(image: $viewModel.selectedImage)
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
            Text("Nouvelle Photo")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            Spacer()
        }
    }

    private var pickerSection: some View {
        HStack(spacing: 12) {
            Text("Défi:").font(.subheadline.bold())
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .textCase(.uppercase)
                .foregroundColor(.white)
            Spacer()
            Picker("", selection: $viewModel.selectedChallenge) {
                ForEach(viewModel.challenges) { ch in
                    Text(ch.title).tag(Optional(ch))
                }
            }
            .pickerStyle(.segmented)
            .modifier(ShakeEffect(animatableData: viewModel.shakeChallenge ? 1 : 0))
        }
        .padding(4)
    }

    private var uploadSection: some View {
        Button {
            viewModel.uploadPhoto()
        } label: {
            HStack {
                if viewModel.isUploadingPhoto {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Enregistrer la photo")
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
        .opacity(viewModel.isUploadingPhoto ? 0.8 : 1.0)
        .padding(4)
    }

    private var photoSection: some View {
        VStack(spacing: 20) {
            if let img = viewModel.selectedImage {
                Image(uiImage: img)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(14)
                    .shadow(radius: 6)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.accentColor.opacity(0.5), lineWidth: 1))
                    .modifier(ShakeEffect(animatableData: viewModel.shakeImage ? 1 : 0))
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

            Button {
                showCamera = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "camera")
                        .font(.system(size: 23, weight: .medium))
                        .foregroundColor(.white)
                    Text("Prendre une photo")
                        .font(.system(.body, design: .rounded).weight(.heavy))
                        .textCase(.uppercase)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(.thinMaterial)
                .cornerRadius(14)
                .shadow(color: Color.blue.opacity(0.38), radius: 10, x: 0, y: 3)
            }

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
        }
    }
}
