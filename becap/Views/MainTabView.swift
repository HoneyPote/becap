//
//  MainTabView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel: MainTabViewModel = MainTabViewModel()

    var body: some View {
        Group {
            TabView {
                if viewModel.challengesDoneFetching {
                    HomeView()
                        .tabItem {
                            Label("Challenge", systemImage: "house.fill")
                        }

                    CameraView()
                        .tabItem {
                            Label("Photo", systemImage: "camera.fill")
                        }
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                } else {
                    ProgressView()
                        .tabItem {
                            Label("Challenge", systemImage: "hourglass")
                        }
                }
            }
        }
        .onAppear {
            NotificationManager.shared.requestAuthorization()
        }
        .task {
            viewModel.fetchFilteredChallenges()
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
