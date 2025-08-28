//
//  CameraView.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI
import Combine
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

    let currentUser: User?

    private var cancellables = Set<AnyCancellable>()

    var challenges: [Challenge] = []
    var takePhotoButtonLabel: String {
        selectedImage == nil ? "Prendre une photo" : "Reprendre une photo"
    }

    init(userManager: UserManager = UserManager.shared,
         challengeManager: ChallengeManager = ChallengeManager.shared) {
        self.currentUser = userManager.currentUser
        self.challengeManager = challengeManager

        observeChallengesChanges()
    }

    func uploadPhoto() {
        isUploadingPhoto = true
        print("🟦 uploadPhoto() appelé")

        guard let challenge = selectedChallenge else {
            updateToast("Veuillez sélectionner un défi.", type: .error)
            withAnimation(.default) { shakeChallenge.toggle() }
            isUploadingPhoto = false
            print("❌ Pas de challenge sélectionné")
            return
        }
        guard let image = selectedImage else {
            updateToast("Veuillez prendre une photo.", type: .error)
            withAnimation(.default) { shakeImage.toggle() }
            isUploadingPhoto = false
            print("❌ Pas d'image sélectionnée")
            return
        }

        Task {
            do {
                try await challengeManager.sendPhotoAndNotify(image: image,
                                                              challenge: challenge,
                                                              descriptionText: descriptionText)
                await MainActor.run {
                    self.playSuccessSoundAndHaptic()
                    self.selectedImage = nil
                    self.descriptionText = ""
                    self.updateToast("Photo uploaded successfully!", type: .success)
                    self.isUploadingPhoto = false
                }
                print("🟩 uploadPhoto() terminé")
            } catch let error {
                await MainActor.run {
                    self.updateToast("Erreur d'URL: \(error.localizedDescription)", type: .error)
                    self.isUploadingPhoto = false
                }
                print("❌ Erreur lors de l'upload ou la notification : \(error)")
            }
        }
    }

    func closeToast() {
        toast.timer?.invalidate()
        withAnimation { toast.isShown = false }
    }

    // MARK: - Private functions

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

// MARK: - Observers
extension CameraViewModel {
    private func observeChallengesChanges() {
        challengeManager.$challenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] challenges in
                self?.challenges = challenges
                if !challenges.isEmpty, let first = challenges.first {
                    self?.selectedChallenge = first
                }
            }
            .store(in: &cancellables)
    }
}
