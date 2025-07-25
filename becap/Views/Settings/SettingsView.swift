//
//  SettingsView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @StateObject private var viewModel = SettingsViewModel()

    @State private var selectedChallenge: Challenge?
    @State private var showingLogoutAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .padding(.top, 42)
                .padding(.bottom, 12)
                .padding(.horizontal, 24)

            List {
                NavigationLink("Créer un nouveau défi", destination: NewDefiView().environmentObject(challengeManager))

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
        .alert("Déconnexion", isPresented: $showingLogoutAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Déconnexion", role: .destructive) {
                viewModel.signOut()
            }
        } message: {
            Text("Voulez-vous vraiment vous déconnecter ?")
        }
    }
}
