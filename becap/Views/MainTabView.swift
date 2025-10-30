//
//  MainTabView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI
import Combine

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: MainTabViewModel = MainTabViewModel()

    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedIndex: Int = 0

    var body: some View {
        CustomTabView(tabs: TabType.allTabItems, selectedIndex: $selectedIndex) { index in
            if viewModel.infosDoneFetching {
                switch TabType(rawValue: index) ?? .home {
                case .home:
                    HomeView()
//                        .withTabBarInset() // TODO: Utile ? Je vois pas de diff perso
                case .camera:
                    CameraView()
                case .settings:
                    SettingsView()
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            NotificationManager.shared.requestAuthorization()
            if appState.deepLink != nil {
                selectedIndex = TabType.home.rawValue
            }
        }
        .task {
            viewModel.fetchInfos()
        }
        .onChange(of: scenePhase) { newPhase in
            viewModel.onChangeOfScenePhase(newPhase)
        }
        .onChange(of: appState.deepLink) { deepLink in
            guard deepLink != nil else { return }
            selectedIndex = TabType.home.rawValue
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
        LinearGradient(gradient: Gradient(colors: [Color(hex: "#6190E8"), Color(hex: "#A7BFE8")]),
                       startPoint: .top,
                       endPoint: .bottom)
    }
}

final class KeyboardResponder: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { frame -> CGFloat in
                guard let window = UIApplication.shared.windows.first else { return 0 }
                return frame.height - window.safeAreaInsets.bottom
            }

        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        Publishers.Merge(willShow, willHide)
            .receive(on: RunLoop.main)
            .assign(to: \.keyboardHeight, on: self)
            .store(in: &cancellables)
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
