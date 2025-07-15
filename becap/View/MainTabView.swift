//
//  MainTabView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Défis", systemImage: "house.fill")
                }

            CameraView()
                .tabItem {
                    Label("Photo", systemImage: "camera.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Menu", systemImage: "gearshape.fill")
                }
        }
    }
}
