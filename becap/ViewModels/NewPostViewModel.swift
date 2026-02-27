//
//  NewPostViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI
import AVFoundation

class NewPostViewModel: ObservableObject {
    @Published var selectedMedia: ChallengeRawMedia?
    @Published var descriptionText: String = ""
    @Published var shakeChallenge: Bool = false
    @Published var shakeImage: Bool = false
    @Published var toast: Toast = Toast(isShown: false, type: .error, message: "")
    @Published var isUploadingPost: Bool = false
    @Published var uploadProgress: Double = 0
    @Published var videoThubmnail: UIImage?

    private let challengeManager: ChallengeManager
    let currentUser: User?
    let currentChallenge: Challenge

    var challenges: [Challenge] = []
    var captureMediaButtonLabel: String {
        selectedMedia == nil ? "Prendre une photo ou une vidéo" : "Reprendre une photo ou une vidéo"
    }
    var uploadButtonLabel: String {
        if isUploadingPost {
            return "Publication en cours..."
        }

        return "Partager le post"
    }

    init(challenge: Challenge,
         rawMedia: ChallengeRawMedia?,
         userManager: UserManager = UserManager.shared,
         challengeManager: ChallengeManager = ChallengeManager.shared) {
        self.currentChallenge = challenge
        self.selectedMedia = rawMedia
        self.currentUser = userManager.currentUser
        self.challengeManager = challengeManager
    }

    func uploadMedia(hasUploaded: @escaping (Bool) -> Void) {
        isUploadingPost = true
        uploadProgress = 0

        guard let media = selectedMedia else {
            updateToast("Veuillez capturer une photo ou une vidéo.", type: .error)
            withAnimation(.default) { shakeChallenge.toggle() }
            isUploadingPost = false
            return
        }

        Task {
            do {
                try await challengeManager.sendPostAndNotify(media: media,
                                                             challenge: currentChallenge,
                                                             descriptionText: descriptionText,
                                                             progressHandler: { [weak self] progress in
                                                                 DispatchQueue.main.async {
                                                                     self?.uploadProgress = progress
                                                                 }
                                                             })

                await MainActor.run {
                    self.playSuccessSoundAndHaptic()
                    self.selectedMedia = nil
                    self.descriptionText = ""
                    self.updateToast("Ton post a été partagé avec succès !", type: .success)
                    self.isUploadingPost = false
					self.uploadProgress = 0

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        hasUploaded(true)
                    }
                }
            } catch let error {
                await MainActor.run {
                    self.updateToast("Erreur d'URL: \(error.localizedDescription)", type: .error)
                    self.isUploadingPost = false
					self.uploadProgress = 0
                    hasUploaded(false)
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

    var uploadDurationLabel: String? {
        guard case .video(let data) = selectedMedia else { return nil }
        let asset = AVAsset(url: data.url)
        let durationSeconds = asset.duration.seconds
        guard durationSeconds.isFinite else { return nil }
        let minutes = Int(durationSeconds) / 60
        let seconds = Int(durationSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
