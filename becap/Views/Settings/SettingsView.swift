//
//  SettingsView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI
import PhotosUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    @State private var showingLogoutAlert = false
    @State private var showCreationToast = false

    // NEW: avatar picker state
    @State private var avatarItem: PhotosPickerItem?
    @State private var isUploadingAvatar = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.petrolToSky.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            Spacer()
                            Text("Paramètres")
                                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            Spacer()
                        }

                        if let currentUser = viewModel.currentUser {
                            GlassCard {
                                headerProfile(user: currentUser)
                            }
                            .padding(.horizontal)
                        }

                        GlassCard {
                            medalSection
                        }
                        .padding(.horizontal)

                        GlassCard {
                            navigationList
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .padding(.bottom, 70 + 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Paramètres")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)
                }
            }
            .navigationBarHidden(true)
            .alert("Déconnexion", isPresented: $showingLogoutAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Déconnexion", role: .destructive) { viewModel.signOut() }
            }
            .overlay(alignment: .bottom) {
                if showCreationToast {
                    ToastView(message: "Défi créé avec succès 🎉", type: .success)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation { showCreationToast = false }
                            }
                        }
                        .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Header (wrapper)

    // Keep this thin; heavier UI is in subviews below to avoid type-check blowups.
    private func headerProfile(user: User) -> some View {
        ProfileHeader(
            user: user,
            avatarItem: $avatarItem,
            isUploading: $isUploadingAvatar,
            onAvatarPicked: { item in
                Task { await handleAvatarSelection(item: item) }
            }
        )
    }

    // MARK: - Sections

    private var medalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎖️ Médailles")
                .font(.headline)
                .foregroundColor(.white.opacity(0.6))

            if let medals = viewModel.currentUser?.medals, !medals.isEmpty {
                let sorted = medals.sorted { $0.achievedDate > $1.achievedDate }
                ParticipantMedalSection(medals: sorted)
            } else {
                Text("Aucune médaille pour le moment.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private var navigationList: some View {
        VStack(spacing: 14) {
            NavigationLink(destination: NewChallengeView(challengeCreated: $showCreationToast)) {
                Label("Créer un nouveau défi", systemImage: "plus.circle")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }

            Button(role: .destructive) {
                showingLogoutAlert = true
            } label: {
                Label("Déconnexion", systemImage: "arrow.backward.circle")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Avatar flow

    private func handleAvatarSelection(item: PhotosPickerItem) async {
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }

        do {
            // Prefer Data to avoid image decode surprises across formats
            if let data = try await item.loadTransferable(type: Data.self) {
                try await viewModel.updateAvatar(data: data) // <-- implement in your VM
            } else {
                print("⚠️ Impossible de charger l'image sélectionnée.")
            }
        } catch {
            print("❌ Upload avatar error: \(error)")
        }
    }
}

//
// MARK: - Subviews (small & compiler-friendly)
//

private struct ProfileHeader: View {
    let user: User
    @Binding var avatarItem: PhotosPickerItem?
    @Binding var isUploading: Bool
    let onAvatarPicked: (PhotosPickerItem) -> Void

    var body: some View {
        VStack(spacing: 12) {
            AvatarEditor(
                avatarUrl: user.photoURL,
                isUploading: isUploading,
                avatarItem: $avatarItem,
                onPicked: onAvatarPicked
            )
            .frame(width: 88, height: 88)

            Text(user.name)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
    }
}

private struct AvatarEditor: View {
    let avatarUrl: String?
    let isUploading: Bool
    @Binding var avatarItem: PhotosPickerItem?
    let onPicked: (PhotosPickerItem) -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvatarCircle(avatarUrl: avatarUrl)
                .overlay(
                    Circle().stroke(.white.opacity(0.25), lineWidth: 0.7)
                )

            PhotosPicker(selection: $avatarItem, matching: .images) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(.black.opacity(0.35))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 0.7))
                    .padding(4)
            }
            .disabled(isUploading)
        }
        .overlay {
            if isUploading {
                ProgressView().progressViewStyle(.circular)
            }
        }
        .onChange(of: avatarItem) { item in
            guard let item else { return }
            onPicked(item)
        }
    }
}

private struct AvatarCircle: View {
    let avatarUrl: String?

    var body: some View {
        Group {
            if let urlStr = avatarUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Color.white.opacity(0.08).overlay(PlaceholderIcon())
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Color.white.opacity(0.08).overlay(PlaceholderIcon())
                    @unknown default:
                        Color.white.opacity(0.08).overlay(PlaceholderIcon())
                    }
                }
            } else {
                Color.white.opacity(0.08).overlay(PlaceholderIcon())
            }
        }
        .clipShape(Circle())
    }

    private struct PlaceholderIcon: View {
        var body: some View {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white.opacity(0.92))
                .padding(10)
        }
    }
}
