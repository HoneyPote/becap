//
//  becapApp.swift
//  becap
//
//  Created by Victor Derveaux on 15/07/2025.
//

import SwiftUI
import FirebaseCore
import OneSignalFramework
import OneSignalFramework
import FirebaseFirestore
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        // Enable verbose logging for debugging (remove in production)
                     OneSignal.Debug.setLogLevel(.LL_VERBOSE)
                     // Initialize with your OneSignal App ID
                     OneSignal.initialize("58d11a0f-cf16-4555-b258-c94d6afa0af3", withLaunchOptions: launchOptions)
                     // Use this method to prompt for push notifications.
                     // We recommend removing this method after testing and instead use In-App Messages to prompt for notification permission.
                     OneSignal.Notifications.requestPermission({ accepted in
                       print("User accepted notifications: \(accepted)")
                     }, fallbackToSettings: false)
        return true
    }
//    func saveOneSignalPlayerIdForCurrentUser(currentUserId: String) {
//        if let playerId = OneSignal.User.pushSubscription.id, !playerId.isEmpty {
//            Firestore.firestore().collection("users").document(currentUserId).setData([
//                "onesignalPlayerId": playerId
//            ], merge: true)
//            print("✅ OneSignal playerId enregistré : \(playerId)")
//        } else {
//            print("❌ Impossible de récupérer le playerId OneSignal.")
//        }
//    }
}

@main
struct becap: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(appState)
        }
    }
}
