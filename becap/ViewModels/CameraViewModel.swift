//
//  CameraView.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI
import Combine
import AVFoundation
import Firebase
import OneSignalFramework

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
     let currentUser: User?

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
            guard let challengeId = challenge.id, let currentUser, let currentUserId = currentUser.id else {
                print("❌ currentUser ou challengeId manquant")
                return
            }

            Task {
                do {
                    print("📤 Upload de la photo en cours...")
                    _ = try await self.challengeManager.uploadPhotoAsync(
                        image: image,
                        challengeId: challengeId,
                        author: currentUser,
                        description: descriptionText
                    )

                    print("✅ Upload réussi, mise à jour progression Firestore...")
                    try await challengeManager.updateParticipantProgress(
                        for: challengeId,
                        userId: currentUserId,
                        date: Date()
                    )

                    // Récupérer playerIds
                    print("🔍 Recherche des playerIds OneSignal des autres participants...")
                    let playerIds = try await fetchOtherParticipantsPlayerIds(
                        challenge: challenge,
                        excludingUserId: currentUserId
                    )
                    print("🎯 playerIds trouvés : \(playerIds)")

                    // Envoyer notif
                    if !playerIds.isEmpty {
                        print("📬 Envoi de la notification à : \(playerIds)")
                        sendPhotoNotification(
                            to: playerIds,
                            authorName: currentUser.name,
                            challengeTitle: challenge.title
                        )
                    } else {
                        print("⚠️ Aucun playerId OneSignal trouvé pour les autres participants")
                    }

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

        private func fetchOtherParticipantsPlayerIds(challenge: Challenge, excludingUserId: String) async throws -> [String] {
            let uids = challenge.participantUids.filter { $0 != excludingUserId }
            print("🔎 Recherche Firestore pour les uids : \(uids)")
            let db = Firestore.firestore()
            var playerIds: [String] = []
       let currentPlayerId = OneSignal.User.pushSubscription.id

            for uid in uids {
                let snap = try await db.collection("users").document(uid).getDocument()
                if let data = snap.data(),
                   let playerId = data["onesignalPlayerId"] as? String,
                   !playerId.isEmpty, playerId != currentPlayerId {
                    playerIds.append(playerId)
                    print("   ✅ Trouvé playerId : \(playerId) pour uid : \(uid)")
                } else {
                    print("   ⚠️ Aucun playerId OneSignal pour uid : \(uid)")
                }
            }
            return playerIds
        }

        // --- ta fonction d'envoi OneSignal ---
    func sendPhotoNotification(to playerIds: [String], authorName: String, challengeTitle: String) {
        let url = URL(string: "https://onesignal.com/api/v1/notifications")!
        let payload: [String: Any] = [
            "app_id": "58d11a0f-cf16-4555-b258-c94d6afa0af3",
            "include_player_ids": playerIds,
            "headings": [
                "en": "Nouveau post dans \"\(challengeTitle)\"",
                "fr": "Nouveau post dans \"\(challengeTitle)\""
            ],
            "contents": [
                "en": "\(authorName) a posté une nouvelle photo !",
                "fr": "\(authorName) a posté une nouvelle photo !"
            ],
            "ios_sound": "default"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic os_v2_app_ldirud6pczcvlmsyzfgwv6qk6mxcvfhmnbcuijvwhdlo64mje7ovicdd6wbq36toy6lyley5gnfxdnz3wi2q3dzvehqlyjk5meujeni", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        print("   ➡️ Requête envoyée : \(payload)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Push notification error: \(error)")
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("OneSignal notif status: \(httpResponse.statusCode)")
            }
            if let data = data, let body = String(data: data, encoding: .utf8) {
                print("OneSignal response body: \(body)")
            }
        }.resume()

        print("Sending to playerIds:", playerIds)
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
