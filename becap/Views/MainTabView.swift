//
//  MainTabView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel: MainTabViewModel = MainTabViewModel()
    @State private var selectedIndex: Int = 0

    var body: some View {
        CustomTabView(tabs: TabType.allTabItems, selectedIndex: $selectedIndex) { index in
            Group {
                if viewModel.infosDoneFetching {
                    switch TabType(rawValue: index) ?? .home {
                    case .home:
                        HomeView()
                            .withTabBarInset()
                    case .camera:
                        CameraView()
                    case .settings:
                        SettingsView()
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .onAppear {
            NotificationManager.shared.requestAuthorization()
        }
        .task {
                   viewModel.fetchInfos()
               }
        .overlay {
            if let medal = viewModel.medal {
                MedalPopupView(medal: medal, onDismiss: viewModel.dismissMedalPopup)
                    .transition(.scale)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

extension LinearGradient {
    static var petrolToSky: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#6190E8"),
                Color(hex: "#A7BFE8"),
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}



import SwiftUI
import Combine

final class KeyboardResponder: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    private var cancellableSet: Set<AnyCancellable> = []

    init() {
        let willShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }

        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        Publishers.Merge(willShow, willHide)
            .receive(on: RunLoop.main)
            .assign(to: \.keyboardHeight, on: self)
            .store(in: &cancellableSet)
    }
}



// Extension super pratique
extension View {
    func withTabBarInset(_ height: CGFloat = 72) -> some View {
        self.safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: height)
        }
    }
}
