//
//  homeView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

// ChallengeApp/Views/HomeView.swift

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var defiManager: DefiManager
    @State private var showDeleteAlert = false
    @State private var defiToDelete: Defi?

    var body: some View {
        NavigationView {
            VStack {
                Text("Liste des défis")
                    .font(.title)
                    .padding()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                        ForEach(defiManager.defis) { defi in
                            DefiCell(defi: defi) {
                                deleteDefi(defi)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Accueil")
        }
        .alert("Delete this challenge?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let defi = defiToDelete {
                    // Remove all photos related to this defi
                    let photosToRemove = defiManager.photos.filter { $0.defiId == defi.id }
                    for photo in photosToRemove {
                        try? FileManager.default.removeItem(atPath: photo.imagePath)
                    }
                    defiManager.photos.removeAll { $0.defiId == defi.id }

                    // Remove the defi and its notifications
                    defiManager.removeDefi(defi)
                    defiToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                defiToDelete = nil
            }
        }
    }

    func deleteDefi(_ defi: Defi) {
        defiToDelete = defi
        showDeleteAlert = true
    }
}
