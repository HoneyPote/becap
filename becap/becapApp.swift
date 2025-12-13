//
//  becapApp.swift
//  becap
//
//  Created by Victor Derveaux on 15/07/2025.
//

import SwiftUI
import FirebaseFirestore

import SwiftUI
import FirebaseCore
import OneSignalFramework   // ⬅️ important

// becapApp.swift (AppDelegate)

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // ✅ Appelle le setup centralisé
        NotificationService.shared.setupOneSignal(didFinishLaunchingWithOptions: launchOptions)

        // (Optionnel) petit log de confort :
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("ℹ️ AppDelegate check – pid:", OneSignal.User.pushSubscription.id ?? "nil",
                  "token:", OneSignal.User.pushSubscription.token ?? "nil")
        }

        return true
    }

    private func updateFirestoreWithPlayerId(_ playerId: String) {
        guard let userId = UserManager.shared.currentUser?.id else {
            print("⚠️ Aucun utilisateur connecté pour enregistrer le playerId")
            return
        }
        Firestore.firestore().collection("users").document(userId).updateData([
            "onesignalPlayerId": playerId
        ]) { error in
            if let error = error {
                print("❌ Erreur Firestore : \(error)")
            } else {
                print("✅ Firestore mis à jour avec le playerId")
            }
        }
    }
}

@main
struct becap: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var appState = AppState.shared
    @StateObject private var deepLinkRouter = DeepLinkRouter()
    @StateObject private var store = StoreManager()

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(appState)
                .environmentObject(deepLinkRouter)
                .environmentObject(store)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL {
                        deepLinkRouter.handle(url: url)
                    }
                }

                .onOpenURL { url in
                    deepLinkRouter.handle(url: url)
                }
                .task {
                    await store.loadProducts()
                    await store.refreshEntitlements()
                }
        }
    }
}
