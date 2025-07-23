//
//  SettingsView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var selectedChallenge: Challenge?
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 42)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 24)

                // Picker initial
                if !challengeManager.challenges.isEmpty {
                    Picker("Défi à configurer", selection: $selectedChallenge) {
                        ForEach(challengeManager.challenges, id: \.id) { challenge in
                            Text(challenge.title).tag(Optional(challenge))
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)
                }

                List {
                    NavigationLink("Créer un nouveau défi", destination: NewDefiView())
                    NavigationLink("Rejoindre un défi", destination: JoinDefiView())

                    if let defi = selectedChallenge ?? challengeManager.challenges.first,
                       let idx = challengeManager.challenges.firstIndex(where: { $0.id == defi.id }) {
                        NavigationLink(
                            "Notifications",
                            destination: NotificationSettingsView(
                                vm: NotificationSettingsViewModel(
                                    config: challengeManager.challenges[idx].notificationsConfig ?? [],
                                    duration: defi.duration
                                ),
                                onSave: { newConfig in
                                    challengeManager.updateNotifications(for: defi, config: newConfig)
                                }
                            )
                        )
                    } else {
                        Label("Notifications", systemImage: "bell")
                            .foregroundColor(.gray)
                    }

                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        Label("Déconnexion", systemImage: "arrow.backward.circle")
                            .foregroundColor(.red)
                    }
                }
                .listStyle(.insetGrouped)
                .background(LinearGradient.petrolToSky.ignoresSafeArea())
            }
            .background(LinearGradient.petrolToSky.ignoresSafeArea())
            .onAppear {
                if selectedChallenge == nil, let first = challengeManager.challenges.first {
                    selectedChallenge = first
                }
            }
            .alert("Déconnexion", isPresented: $showingLogoutAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Déconnexion", role: .destructive) {
                    do {
                        try AccountManager().signOut()
                        UserManager.shared.resetUser()
                    } catch {
                        print("Erreur lors de la déconnexion : \(error.localizedDescription)")
                    }
                }
            } message: {
                Text("Voulez-vous vraiment vous déconnecter ?")
            }
        }
        .navigationViewStyle(.stack)
    }
}
