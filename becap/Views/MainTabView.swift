//
//  MainView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI
import Combine

struct MainView: View {
    @StateObject private var viewModel: MainTabViewModel = MainTabViewModel()

    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter

    @State private var selectedIndex: Int = 0

    var body: some View {
        HomeView()
            .onAppear {
                NotificationManager.shared.requestAuthorization()
            }
            .task {
                viewModel.fetchInfos()
            }
            .onChange(of: scenePhase) { newPhase in
                viewModel.onChangeOfScenePhase(newPhase)
            }
            .overlay {
                if !viewModel.infosDoneFetching {
                    ProgressView()
                }
            }
            .overlay {
                if !viewModel.medals.isEmpty {
                    MedalPopupView(medals: viewModel.medals, onDismiss: viewModel.dismissMedalPopup)
                        .transition(.scale)
                }
            }
            .navigationBarBackButtonHidden(true)
            .onChange(of: deepLinkRouter.pendingCalendarChallengeId) { id in
                guard id != nil else { return }
                selectedIndex = 0
            }
    }
}

extension LinearGradient {
    static var petrolToSky: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 11/255, green: 44/255, blue: 87/255),   // #0B2C57 - bleu profond (haut)
                Color(red: 45/255, green: 110/255, blue: 166/255)   // #2D6EA6 - bleu moyen (bas)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
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
            Color.clear.frame(height: height + 16)
        }
    }
}
extension UIImage {
    func resized(toMaxWidth width: CGFloat) -> UIImage {
        guard width > 0, size.width > 0, size.height > 0 else { return self }

        // Limit both dimensions and never enlarge an already-small image. Camera
        // images may be portrait (or even panoramic); limiting only their width
        // could allocate a very tall bitmap and make iOS terminate the app for
        // excessive memory use without reporting a Swift crash in Xcode.
        let scale = min(1, width / max(size.width, size.height))
        guard scale < 1 else { return self }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}


struct PetrolSkyHeroBackground: View {
    var imageName: String = "bg_mountain"     // your asset name
    var imageOpacity: CGFloat = 0.9           // image strength
    var bottomVignette: CGFloat = 0.30        // darken bottom for cards/tab

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#6190E8"), Color(hex: "#A7BFE8")]),
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                // Image: scaledToFit (so no crop/zoom), anchored at bottom
                VStack(spacing: 0) {
                    Spacer()
                    Image(imageName)
                        .resizable()
                        .scaledToFit()                 // <- prevents zoom/crop
                        .frame(width: geo.size.width)  // fit by width
                        .opacity(imageOpacity)
                        .blendMode(.multiply)          // merges nicely with gradient
                        .accessibilityHidden(true)
                }
                .ignoresSafeArea(edges: .bottom)

                // Very soft haze at top + vignette at bottom for contrast
                LinearGradient(colors: [Color.white.opacity(0.06), .clear],
                               startPoint: .top, endPoint: .center)
                .ignoresSafeArea()

                LinearGradient(colors: [.clear, Color.black.opacity(bottomVignette)],
                               startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea()
            }
        }
    }
}
