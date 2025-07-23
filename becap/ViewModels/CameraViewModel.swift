import SwiftUI
import AVFoundation
import FirebaseStorage

enum ToastType {
    case success
    case error
}

class CameraViewModel: ObservableObject {
    @Published var selectedChallenge: Challenge?
    @Published var participant: String = ""
    @Published var selectedImage: UIImage?
    @Published var showCamera = false
    @Published var descriptionText: String = ""
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success
    @Published var shakeChallenge = false
    @Published var shakeParticipant = false
    @Published var shakeImage = false

    var toastTimer: Timer?
    private let challengeManager: ChallengeManager
    private let prenomKey = "prenomUtilisateur"

    init(challengeManager: ChallengeManager) {
        self.challengeManager = challengeManager
        // Prend le premier challenge si présent
        if let first = challengeManager.challenges.first {
            selectedChallenge = first
        }
        if let prenom = UserDefaults.standard.string(forKey: prenomKey) {
            participant = prenom
        }
    }

    func enregistrerPhoto() {
        guard let image = selectedImage, let challenge = selectedChallenge, let challengeId = challenge.id, let user = UserManager.shared.currentUser else { return }

        Task {
            do {
                _ = try await self.challengeManager.uploadPhotoAsync(image: image,
                                                                     challengeId: challengeId,
                                                                     author: user,
                                                                     description: self.descriptionText)
                await MainActor.run {
                    self.selectedImage = nil
                    self.descriptionText = ""
                    self.showToastMessage("Photo uploaded successfully!", type: .success)
                }
            } catch let error {
                await MainActor.run {
                    self.showToastMessage("Erreur d'URL: \(error.localizedDescription)", type: .error)
                }
            }
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
