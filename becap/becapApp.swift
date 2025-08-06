//
//  becapApp.swift
//  becap
//
//  Created by Victor Derveaux on 15/07/2025.
//

import SwiftUI
import FirebaseCore

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

        if let playerId = OneSignal.User.pushSubscription.id {
            print("✅ playerId récupéré: \(playerId)")

            // 🔁 Update Firestore
            if let currentUserId = UserManager.shared.currentUser?.id {
                Firestore.firestore().collection("users").document(currentUserId).updateData([
                    "onesignalPlayerId": playerId
                ]) { error in
                    if let error = error {
                        print("❌ Erreur update playerId: \(error)")
                    } else {
                        print("✅ playerId mis à jour dans Firestore")
                    }
                }
            }
        } else {
            print("⚠️ Aucun playerId dispo pour l’instant.")
        }
        return true
    }

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
