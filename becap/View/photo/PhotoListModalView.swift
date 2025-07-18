//
//  PhotoListModalView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

// ChallengeApp/Views/PhotoListModalView.swift

import SwiftUI

struct PhotoListModalView: View {
    var date: Date
    var participant: String?
    @EnvironmentObject var defiManager: DefiManager
    @Environment(\.dismiss) var dismiss
    @State private var toDelete: PhotoDefi?
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Photos du \(formatted(date))")
                    .font(.headline)

                if let participant = participant {
                    Text("Filtré: \(participant)")
                } else {
                    Text("Tous les participants")
                }

                let photos = defiManager.photosFor(defiId: defiManager.defis.first?.id ?? UUID(), date: date, participant: participant)

                if photos.isEmpty {
                    Spacer()
                    Text("📸 Aucune photo enregistrée")
                    Spacer()
                } else {
                    ScrollView {
                        ForEach(photos) { photo in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(photo.prenomAuteur)
                                        .font(.subheadline)
                                    Spacer()
                                    Button(role: .destructive) {
                                        toDelete = photo
                                        showDeleteAlert = true
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.bottom, 2)
                                if let uiImage = UIImage(contentsOfFile: photo.imagePath) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 200)
                                        .cornerRadius(10)
                                } else {
                                    Text("Image introuvable")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Détails")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .alert("Supprimer la photo ?", isPresented: $showDeleteAlert, presenting: toDelete) { photo in
                Button("Supprimer", role: .destructive) {
                    supprimer(photo)
                }
                Button("Annuler", role: .cancel) {}
            } message: { _ in
                Text("Cette action est irréversible.")
            }
        }
    }

    func supprimer(_ photo: PhotoDefi) {
        try? FileManager.default.removeItem(atPath: photo.imagePath)
        if let index = defiManager.photos.firstIndex(where: { $0.id == photo.id }) {
            defiManager.photos.remove(at: index)
        }
    }

    func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}
