//
//  HomeViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var defiToDelete: Defi?
    @Published var showDeleteAlert = false

    func confirmDelete(_ defi: Defi) {
        defiToDelete = defi
        showDeleteAlert = true
    }

    func performDelete(defiManager: DefiManager) {
        if let defi = defiToDelete {
            let photosToRemove = defiManager.photos.filter { $0.defiId == defi.id }
            for photo in photosToRemove {
                try? FileManager.default.removeItem(atPath: photo.imagePath)
            }
            defiManager.photos.removeAll { $0.defiId == defi.id }
            defiManager.removeDefi(defi)
            defiToDelete = nil
        }
    }

    func cancelDelete() {
        defiToDelete = nil
        showDeleteAlert = false
    }
}
