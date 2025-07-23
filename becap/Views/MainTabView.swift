//
//  MainTabView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct MainTabView: View {
    // ChallengeManager partagé (injecté depuis login/register)
    @ObservedObject var challengeManager: ChallengeManager

    var body: some View {
        TabView {
            ChallengeView(challengeManager: challengeManager)
                .tabItem {
                    Label("Challenge", systemImage: "house.fill")
                }

            CameraView(challengeManager: challengeManager)
                .tabItem {
                    Label("Photo", systemImage: "camera.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .environmentObject(ChallengeManager.shared)
        .onAppear {
            challengeManager.loadChallenges()
            NotificationManager.shared.requestAuthorization()
        }
        .navigationBarBackButtonHidden(true)
    }
}

extension LinearGradient {
    static var petrolToSky: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 36/255, green: 89/255, blue: 111/255),   // Bleu pétrole
                Color(red: 116/255, green: 207/255, blue: 242/255)  // Bleu ciel
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
