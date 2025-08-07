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
    let pushObserver = PushObserver()
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
        OneSignal.User.pushSubscription.addObserver(pushObserver)
        // 🔄 Ajout de l'observer
               OneSignal.User.pushSubscription.addObserver(pushObserver)

               // 🕒 Fallback : attendre 2s pour récupérer un éventuel playerId tardif
               DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                   if let playerId = OneSignal.User.pushSubscription.id {
                       print("✅ [Fallback] playerId OneSignal : \(playerId)")
                       self.updateFirestoreWithPlayerId(playerId)
                   } else {
                       print("⚠️ [Fallback] Aucun playerId détecté après délai.")
                   }
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


import Foundation
import OneSignalFramework
import FirebaseFirestore
import OneSignalExtension

//
//class PushObserver: NSObject, OSPushSubscriptionObserver {
//    func onPushSubscriptionDidChange(state: OSPushSubscriptionChangedState) {
//        guard let playerId = state.current.id else {
//            print("⚠️ Aucun playerId détecté.")
//            return
//        }
//
//        print("🔄 Nouveau playerId détecté : \(playerId)")
//
//        if let userId = UserManager.shared.currentUser?.id {
//            Firestore.firestore().collection("users").document(userId).updateData([
//                "onesignalPlayerId": playerId
//            ]) { error in
//                if let error = error {
//                    print("❌ Erreur Firestore : \(error)")
//                } else {
//                    print("✅ playerId mis à jour")
//                }
//            }
//        }
//    }
//}


class PushObserver: NSObject, OSPushSubscriptionObserver {
    func onPushSubscriptionDidChange(state: OSPushSubscriptionChangedState) {
        guard let playerId = state.current.id else {
            print("⚠️ Aucun playerId détecté.")
            return
        }

        print("🔄 Nouveau playerId détecté : \(playerId)")

        if let userId = UserManager.shared.currentUser?.id {
            Firestore.firestore().collection("users").document(userId).updateData([
                "onesignalPlayerId": playerId
            ]) { error in
                if let error = error {
                    print("❌ Erreur Firestore : \(error)")
                } else {
                    print("✅ playerId mis à jour")
                }
            }
        }
    }
}
