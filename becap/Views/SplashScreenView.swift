//
//  SplashScreenView.swift
//  becap
//
//  Created by Victor Derveaux on 22/07/2025.
//

import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var viewModel = SplashScreenViewModel()
    @AppStorage("becap.hasSeenWelcome") private var hasSeenWelcome = false

    @State private var animHasFinished: Bool = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.3

    var body: some View {
        Group {
            if viewModel.isReadyToProceed {
                if appState.hasAcceptedLegal {
                    if appState.isLoggedIn {
                        MainView()
                            .id(appState.sessionID) // Reloading root view after every login
                    } else if !hasSeenWelcome {
                        WelcomeView {
                            hasSeenWelcome = true
                        }
                    } else {
                        LoginView()
                    }
                } else {
                    TermsAcceptanceView()
                }
            } else {
                splashScreen
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .animation(reduceMotion ? nil : .easeInOut, value: appState.isLoggedIn)
    }

    var splashScreen: some View {
        ZStack {
            BecapBrandBackground()
            VStack {
                Image(systemName: "flag.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .padding(.bottom, 16)

                Text("BE CAP")
                    .font(BecapTypography.display)
                    .foregroundColor(.white)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(reduceMotion ? nil : .easeIn(duration: 0.7)) {
                    self.scale = 1.0
                    self.opacity = 1.0
                }
            }
        }
    }
}
