//
//  SettingsView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    @State private var showingLogoutAlert = false
    @State private var showCreationToast = false

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
                Button("Déconnexion", role: .destructive) {
                    viewModel.signOut()
                }
            }
            .overlay(alignment: .bottom) {
                if showCreationToast {
                    ToastView(
                        message: "Défi créé avec succès 🎉",
                        type: .success
                    )
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

    //TODO: AJOUTER LA POSSIBLITÉ DE METTRE UN AVATAR OU UNE PHOTO OU ICONE
    private func headerProfile(user: User) -> some View {
        VStack(spacing: 12) {
            ProfileAvatarView(name: user.name, photoURL: user.photoURL)

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
            //TODO: passer le challengeID et appeller la vue notif
            //            NavigationLink(destination: NotificationSettingsView()) {
            //                Label("Créer un nouveau défi", systemImage: "bell.fill")
            //                    .font(.system(size: 17, weight: .medium))
            //                    .foregroundColor(.white)
            //                    .padding(10)
            //                    .background(Circle().fill(.ultraThinMaterial))
            //                    .shadow(radius: 4)
            //            }
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
}

private struct ProfileAvatarView: View {
    let name: String
    let photoURL: String?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.18))
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                )

            if let photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        ProgressView()
                    case .failure:
                        initialsView
                    @unknown default:
                        initialsView
                    }
                }
                .clipShape(Circle())
            } else {
                initialsView
            }
        }
        .frame(width: 90, height: 90)
    }

    private var initialsView: some View {
        Text(initials(from: name))
            .font(.system(.title2, design: .rounded).weight(.heavy))
            .foregroundColor(.white)
    }

    private func initials(from name: String) -> String {
        let components = name.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }
        return String(initials)
    }
}
