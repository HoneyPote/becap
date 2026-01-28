//
//  GlobalAlertManager.swift
//  becap
//
//  Created by Victor Derveaux on 30/07/2025.
//

import SwiftUI
import AudioToolbox

class GlobalAlertManager: ObservableObject {
    static let shared = GlobalAlertManager()

    @Published var isShown: Bool = false
    @Published var message: String = ""
    @Published var currentMedals: [UserMedal] = []

    private var timer: Timer?
    private init() {}

    func show(medals: [UserMedal], duration: TimeInterval = 2.5) {
        guard let userId = ChallengeManager.shared.currentUser?.id else { return }
        let unshown = medals.filter { medal in
            let key = "medal_shown_\(userId)_\(medal.name)_\(medal.challengeId)_\(medal.achievedDate.formatted(.iso8601))"
            if UserDefaults.standard.bool(forKey: key) {
                print("🔁 Médaille déjà affichée pour ce défi")
                return false
            }
            UserDefaults.standard.set(true, forKey: key)
            return true
        }

        guard !unshown.isEmpty else { return }

        self.currentMedals = unshown
        self.isShown = true
        playFeedback(for: unshown)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.isShown = false
            self?.currentMedals = []
        }
    }

    func dismiss() {
        self.isShown = false
        self.currentMedals = []
        timer?.invalidate()
    }

    // Privates

    private func playFeedback(for medals: [UserMedal]) {
        let generator = UINotificationFeedbackGenerator()
        if medals.count > 1 {
            generator.notificationOccurred(.warning)
            AudioServicesPlaySystemSound(1025)
        } else {
            generator.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1057)
        }
    }
}
