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

    private var defiManager: DefiManager

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
}
