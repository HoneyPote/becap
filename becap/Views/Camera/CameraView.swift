//
//  CameraView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//
import SwiftUI

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat = 0
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 10 * sin(animatableData * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

struct CameraView: View {
    @EnvironmentObject var defiManager: DefiManager
    @StateObject private var vm: CameraViewModel

    // Injection du ViewModel
    init(defiManager: DefiManager) {
        _vm = StateObject(wrappedValue: CameraViewModel(defiManager: defiManager))
    }
    init(viewModel: CameraViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                infoCard
                photoCard
                saveButton
            }
            .padding([.horizontal, .bottom])
            .padding(.top, 2)
        }
        .background(LinearGradient.petrolToSky.ignoresSafeArea())
        .navigationTitle("Prendre une photo")
        .sheet(isPresented: $vm.showCamera, onDismiss: {}) {
            CameraCaptureView(image: $vm.selectedImage)
        }
        .overlay(toastView)
        .onAppear {
            if vm.selectedDefi == nil, let first = defiManager.defis.first {
                vm.selectedDefi = first
            }
        }
    }

    // MARK: - Sous-vues privées

    private var header: some View {
        Text("Nouvelle photo")
            .font(.largeTitle.bold())
            .foregroundColor(.white)
            .padding(.top, 12)
            .shadow(radius: 8)
    }

    private var infoCard: some View {
        GroupBox {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Défi").font(.subheadline.bold())
                    Picker("Défi", selection: $vm.selectedDefi) {
                        ForEach(defiManager.defis) { defi in
                            Text(defi.name).tag(Optional(defi))
                        }
                    }
                    .pickerStyle(.menu)
                    .modifier(ShakeEffect(animatableData: vm.shakeDefi ? 1 : 0))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Prénom").font(.subheadline.bold())
                    TextField("Votre prénom", text: $vm.participant)
                        .textFieldStyle(.roundedBorder)
                        .modifier(ShakeEffect(animatableData: vm.shakeParticipant ? 1 : 0))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.13), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var photoCard: some View {
        GroupBox {
            VStack(spacing: 18) {
                if let image = vm.selectedImage {
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
                        .modifier(ShakeEffect(animatableData: vm.shakeImage ? 1 : 0))
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
                    .modifier(ShakeEffect(animatableData: vm.shakeImage ? 1 : 0))
                }

                takePhotoButton

                TextField("Description (optionnelle)", text: $vm.descriptionText)
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
        let canTakePhoto = true
        Button {
            vm.showCamera = true
        } label: {
            Label(vm.selectedImage == nil ? "Prendre une photo" : "Reprendre une photo", systemImage: "camera.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    canTakePhoto
                        ? AnyView(Color.clear.background(.thinMaterial))
                        : AnyView(Color.gray.opacity(0.4))
                )
                .foregroundColor(.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.black.opacity(0.11), radius: 7, x: 0, y: 3)
        }
        .disabled(!canTakePhoto)
        .opacity(canTakePhoto ? 1.0 : 0.5)
    }

    @ViewBuilder
    private var saveButton: some View {
        Button {
            if vm.selectedDefi == nil {
                vm.showToastMessage("Veuillez sélectionner un défi.", type: .error)
                withAnimation(.default) { vm.shakeDefi.toggle() }
                return
            }
            if vm.selectedImage == nil {
                vm.showToastMessage("Veuillez prendre une photo.", type: .error)
                withAnimation(.default) { vm.shakeImage.toggle() }
                return
            }
            if vm.participant.trimmingCharacters(in: .whitespaces).isEmpty {
                vm.showToastMessage("Veuillez saisir votre prénom.", type: .error)
                withAnimation(.default) { vm.shakeParticipant.toggle() }
                return
            }
            vm.enregistrerPhoto()
        } label: {
            Label("Enregistrer la photo", systemImage: "square.and.arrow.down.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.clear.background(.thinMaterial))
                .foregroundColor(.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.black.opacity(0.13), radius: 8, x: 0, y: 3)
        }
        .padding(.top, 2)
    }

    private var toastView: some View {
        Group {
            if vm.showToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Spacer()
                        Text(vm.toastMessage)
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 22)
                            .background(vm.toastType == .success ? Color.green.opacity(0.95) : Color.red.opacity(0.95))
                            .cornerRadius(28)
                            .shadow(radius: 16)
                        Button(action: {
                            vm.toastTimer?.invalidate()
                            withAnimation { vm.showToast = false }
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
    }
}
