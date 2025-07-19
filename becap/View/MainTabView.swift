//
//  MainTabView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var defiManager: DefiManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Défis", systemImage: "house.fill")
                }

            CameraView(defiManager: defiManager)   // <-- Correction ici
                .tabItem {
                    Label("Photo", systemImage: "camera.fill")
                }

            SettingsView(defiManager: defiManager)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
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
