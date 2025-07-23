//
//  SettingsViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var selectedDefi: Defi?
    @Published private(set) var defis: [Defi] = []
    @Published var isSignedOut: Bool = false
    @Published var signoutError: String? = nil

    private var defiManager: DefiManager
    private let accountManager: AccountServiceProtocol = AccountService()

    init(defiManager: DefiManager) {
        self.defiManager = defiManager
        self.defis = defiManager.defis
        // Sélectionne le premier défi par défaut si dispo
        if let first = defis.first {
            selectedDefi = first
        }
    }

    func refresh() {
        defis = defiManager.defis
        if selectedDefi == nil, let first = defis.first {
            selectedDefi = first
        }
    }

    // Pour le picker ou accès direct
    var availableDefis: [Defi] { defis }

    // Utilisé pour le bouton notifications
    var currentDefi: Defi? {
        selectedDefi ?? defis.first
    }

    func signOut() {
        Task {
            do {
                try accountManager.signOut()
                self.isSignedOut = true
            } catch {
                signoutError = error.localizedDescription
            }
        }
    }
}
