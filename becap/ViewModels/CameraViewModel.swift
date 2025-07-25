//
//  CameraView.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI
import AVFoundation

class CameraViewModel: ObservableObject {
    @Published var selectedChallenge: Challenge?
    @Published var selectedImage: UIImage?
    @Published var descriptionText: String = ""
    @Published var shakeChallenge: Bool = false
    @Published var shakeImage: Bool = false
    @Published var toast: Toast = Toast(isShown: false, type: .error, message: "")
    @Published var isUploadingPhoto: Bool = false

    private let challengeManager: ChallengeManager
    private let currentUser: User?

    let challenges: [Challenge]

    var takePhotoButtonLabel: String {
        selectedImage == nil ? "Prendre une photo" : "Reprendre une photo"
    }

    init(challengeManager: ChallengeManager = ChallengeManager.shared) {
        self.challengeManager = challengeManager
        self.currentUser = UserManager.shared.currentUser
        self.challenges = challengeManager.challenges

        if !challenges.isEmpty, let first = challenges.first {
            selectedChallenge = first
        }
    }

    func uploadPhoto() {
        isUploadingPhoto = true

        guard let challenge = selectedChallenge else {
            updateToast("Veuillez sélectionner un défi.", type: .error)
            withAnimation(.default) { shakeChallenge.toggle() }
            isUploadingPhoto = false
            return
        }

        guard let image = selectedImage else {
            updateToast("Veuillez prendre une photo.", type: .error)
            withAnimation(.default) { shakeImage.toggle() }
            isUploadingPhoto = false
            return
        }

        guard let challengeId = challenge.id, let user = currentUser else { return }

        Task {
            do {
                _ = try await self.challengeManager.uploadPhotoAsync(image: image,
                                                                     challengeId: challengeId,
                                                                     author: user,
                                                                     description: descriptionText)
                await MainActor.run {
                    self.playSuccessSoundAndHaptic()
                    self.selectedImage = nil
                    self.descriptionText = ""
                    self.updateToast("Photo uploaded successfully!", type: .success)
                    self.isUploadingPhoto = false
                }
            } catch let error {
                await MainActor.run {
                    self.updateToast("Erreur d'URL: \(error.localizedDescription)", type: .error)
                    self.isUploadingPhoto = false
                }
            }
        }
    }

    func closeToast() {
        toast.timer?.invalidate()
        withAnimation { toast.isShown = false }
    }

    // MARK: Private methods

    private func updateToast(_ message: String, type: ToastType) {
        toast.timer?.invalidate()
        toast.message = message
        toast.type = type
        withAnimation { toast.isShown = true }
        toast.timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            withAnimation { self.toast.isShown = false }
        }
    }

    private func playSuccessSoundAndHaptic() {
        AudioServicesPlaySystemSound(1057)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
