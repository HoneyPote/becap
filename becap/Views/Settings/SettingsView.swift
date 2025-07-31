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
            ScrollView {
                VStack(spacing: 20) {
                    if let currentUser = viewModel.currentUser {
                        headerProfile(user: currentUser)
                    }

                    medalSection
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)

                    navigationList
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)

                }
                .padding(.top)
            }
            .background(LinearGradient.petrolToSky.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .alert("Déconnexion", isPresented: $showingLogoutAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Déconnexion", role: .destructive) {
                viewModel.signOut()
            }
        }
        .overlay(alignment: .bottom) {
            if showCreationToast {
                ToastView(message: "Défi créé avec succès 🎉", systemImage: "checkmark.circle")
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showCreationToast = false
                            }
                        }
                    }
                    .padding(.bottom, 40)
            }
        }
    }

    private func headerProfile(user: User) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.white.opacity(0.9))

            Text(user.name)
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var medalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎖️ Médailles:")
                .font(.headline)
                .foregroundColor(.white)

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
        VStack(spacing: 12) {
            NavigationLink(destination: NewChallengeView(challengeCreated: $showCreationToast)) {
                Label("Créer un nouveau défi", systemImage: "plus.circle")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(role: .destructive) {
                showingLogoutAlert = true
            } label: {
                Label("Déconnexion", systemImage: "arrow.backward.circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
