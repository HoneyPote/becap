//
//  SettingsView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

// ChallengeApp/Views/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Créer un nouveau défi", destination: NewDefiView())
                NavigationLink("Rejoindre un défi", destination: JoinDefiView())
                NavigationLink("Notifications", destination: Text("Paramètres de notifications"))
            }
            .navigationTitle("Menu")
        }
    }
}
