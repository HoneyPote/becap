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

    private var cancellables = Set<AnyCancellable>()

    private let challengeManager: ChallengeManager
    private let currentUser: User?

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

        guard let challengeId = challenge.id, let currentUser, let currentUserId = currentUser.id else { return }

        Task {
            do {
                _ = try await self.challengeManager.uploadPhotoAsync(image: image,
                                                                     challengeId: challengeId,
                                                                     author: currentUser,
                                                                     description: descriptionText)

                try await challengeManager.updateParticipantProgress(for: challengeId,
                                                                     userId: currentUserId,
                                                                     date: Date())

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
