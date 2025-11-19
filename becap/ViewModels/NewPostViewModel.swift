//
//  NewPostViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI
import Combine
import AVFoundation

class NewPostViewModel: ObservableObject {
    @Published var selectedChallenge: Challenge?
    @Published var selectedMedia: ChallengeRawMedia?
    @Published var descriptionText: String = ""
    @Published var shakeChallenge: Bool = false
    @Published var shakeImage: Bool = false
    @Published var toast: Toast = Toast(isShown: false, type: .error, message: "")
    @Published var isUploadingPost: Bool = false
    @Published var videoThubmnail: UIImage?

    let currentUser: User?
    private let challengeManager: ChallengeManager

    var challenges: [Challenge] = []
    var captureMediaButtonLabel: String {
        selectedMedia == nil ? "Prendre une photo ou une vidéo" : "Reprendre une photo ou une vidéo"
    }

    private var cancellables = Set<AnyCancellable>()

    init(userManager: UserManager = UserManager.shared,
         challengeManager: ChallengeManager = ChallengeManager.shared) {
        self.currentUser = userManager.currentUser
        self.challengeManager = challengeManager

        observeChallengesChanges()
    }

    func uploadMedia() {
        isUploadingPost = true

        guard let media = selectedMedia, let challenge = selectedChallenge else {
            updateToast("Veuillez sélectionner un média et défi.", type: .error)
            withAnimation(.default) { shakeChallenge.toggle() }
            isUploadingPost = false
            return
        }

        Task {
            do {
                try await challengeManager.sendPostAndNotify(media: media, challenge: challenge, descriptionText: descriptionText)

                await MainActor.run {
                    self.playSuccessSoundAndHaptic()
                    self.selectedMedia = nil
                    self.descriptionText = ""
                    self.updateToast("Post uploaded successfully!", type: .success)
                    self.isUploadingPost = false
                }
            } catch let error {
                await MainActor.run {
                    self.updateToast("Erreur d'URL: \(error.localizedDescription)", type: .error)
                    self.isUploadingPost = false
                }
            }
        }
    }

    func updateSelectedMedia(_ media: ChallengeRawMedia) {
        selectedMedia = media
    }

    func closeToast() {
        toast.timer?.invalidate()
        withAnimation { toast.isShown = false }
    }

    func eraseMedia() {
        selectedMedia = nil
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
extension NewPostViewModel {
    private func observeChallengesChanges() {
        challengeManager.$challenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] challenges in
                guard let self else { return }

                self.challenges = challenges.filter { $0.status == .active }

                if !self.challenges.isEmpty, let first = self.challenges.first {
                    self.selectedChallenge = first
                }
            }
            .store(in: &cancellables)
    }
}
