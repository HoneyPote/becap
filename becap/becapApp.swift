//
//  becapApp.swift
//  becap
//
//  Created by Victor Derveaux on 15/07/2025.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        NotificationService.shared.setupOneSignal()

        return true
    }
}

@main
struct becap: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var appState = AppState.shared
    @StateObject private var deepLinkRouter = DeepLinkRouter()

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(appState)
                .environmentObject(deepLinkRouter)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL {
                        deepLinkRouter.handle(url: url)
                    }
                }

                .onOpenURL { url in
                    deepLinkRouter.handle(url: url)
                }
        }
    }
}
