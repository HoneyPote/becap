//
//  CameraView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

// ChallengeApp/Views/CameraView.swift

import SwiftUI
import PhotosUI

struct CameraView: View {
    @EnvironmentObject var defiManager: DefiManager
    @State private var selectedDefi: Defi?
    @State private var participant = ""
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Picker("Défi", selection: $selectedDefi) {
                    Text("Choisir un défi").tag(Defi?.none)
                    ForEach(defiManager.defis) { defi in
                        Text(defi.nom).tag(Optional(defi))
                    }
                }
                .pickerStyle(.menu)

                TextField("Votre prénom", text: $participant)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(12)
                }

                Button("Prendre une photo") {
                    showCamera = true
                }
                .buttonStyle(.borderedProminent)

                Button("Enregistrer la photo") {
                    enregistrerPhoto()
                }
                .disabled(selectedImage == nil || selectedDefi == nil || participant.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
            .navigationTitle("Prendre une photo")
            .sheet(isPresented: $showCamera) {
                CameraCaptureView(image: $selectedImage)
            }
            .alert("Info", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    func enregistrerPhoto() {
        guard let image = selectedImage, let defi = selectedDefi else { return }
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        let filename = UUID().uuidString + ".jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: url)
            let photo = PhotoDefi(defiId: defi.id, date: Date(), prenomAuteur: participant, imagePath: url.path)
            defiManager.ajouterPhoto(photo)
            alertMessage = "Photo enregistrée avec succès"
            selectedImage = nil
        } catch {
            alertMessage = "Erreur lors de l'enregistrement: \(error.localizedDescription)"
        }
        showAlert = true
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
