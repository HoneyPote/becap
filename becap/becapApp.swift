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
    FirebaseApp.configure()

    return true
  }
}

@main
struct becap: App {
    @StateObject private var defiManager = DefiManager()

    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(defiManager)
                .onAppear {
                    defiManager.loadDefis()
                    defiManager.loadPhotos()
                    NotificationManager.shared.requestAuthorization()
                }
        }
    }
}
