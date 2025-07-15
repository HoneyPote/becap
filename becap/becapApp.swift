//
//  becapApp.swift
//  becap
//
//  Created by Victor Derveaux on 15/07/2025.
//

import SwiftUI

@main
struct becap: App {
    @StateObject private var defiManager = DefiManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(defiManager)
                .onAppear {
                    defiManager.chargerDefis()
                    defiManager.chargerPhotos()
                }
        }
    }
}
