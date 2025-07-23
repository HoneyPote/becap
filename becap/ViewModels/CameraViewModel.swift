//
//  CameraViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI
import AVFoundation

enum ToastType {
    case success
    case error
}
class CameraViewModel: ObservableObject {
    @Published var selectedDefi: Defi?
    @Published var participant: String = ""
    @Published var selectedImage: UIImage?
    @Published var showCamera = false
    @Published var descriptionText: String = ""
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success
    @Published var shakeDefi = false
    @Published var shakeImage = false
    @Published var shakeParticipant = false

    var toastTimer: Timer?
    private let defiManager: DefiManager
    private let prenomKey = "prenomUtilisateur"

    init(defiManager: DefiManager) {
        self.defiManager = defiManager
        if let first = defiManager.defis.first {
            selectedDefi = first
        }
        if let prenom = UserDefaults.standard.string(forKey: prenomKey) {
            participant = prenom
        }
    }

    func enregistrerPhoto() {
        guard let image = selectedImage, let defi = selectedDefi else { return }
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        let filename = UUID().uuidString + ".jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: url)
            let photo = PhotoDefi(
                defiId: defi.id,
                date: Date(),
                prenomAuteur: participant,
                imagePath: url.path,
                description: descriptionText.isEmpty ? nil : descriptionText
            )
            defiManager.addPhoto(photo)
            UserDefaults.standard.set(participant, forKey: prenomKey)
            playSuccessSoundAndHaptic()
            showToastMessage("Photo enregistrée avec succès", type: .success)
            selectedImage = nil
            descriptionText = ""
        } catch {
            showToastMessage("Erreur lors de l'enregistrement: \(error.localizedDescription)", type: .error)
        }
    }

    func showToastMessage(_ message: String, type: ToastType) {
        toastTimer?.invalidate()
        toastMessage = message
        toastType = type
        withAnimation { showToast = true }
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            withAnimation { self.showToast = false }
        }
    }

    func playSuccessSoundAndHaptic() {
        AudioServicesPlaySystemSound(1057)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
