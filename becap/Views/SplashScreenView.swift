//
//  SplashScreenView.swift
//  becap
//
//  Created by Victor Derveaux on 22/07/2025.
//

import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject private var appState: AppState

    @StateObject private var viewModel = SplashScreenViewModel()

    @State private var animHasFinished: Bool = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.3

    var body: some View {
        Group {
            if viewModel.isReadyToProceed {
                if appState.isLoggedIn {
                    MainTabView()
                        .id(appState.sessionID) // 💥 Vue root recréée à chaque changement
                } else {
                    LoginView()
                }
            } else {
                splashScreen
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .animation(.easeInOut, value: appState.isLoggedIn)
    }

    var splashScreen: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 122/255, green: 182/255, blue: 242/255), // #7AB6F2
                    Color(red: 36/255, green: 107/255, blue: 206/255)   // #246BCE
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Image(systemName: "flag.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .padding(.bottom, 16)

                Text("Becap")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 1.2)) {
                    self.scale = 1.0
                    self.opacity = 1.0
                }
            }
        }
    }
}
