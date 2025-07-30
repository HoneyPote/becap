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
    @Published var currentMedal: UserMedal?

    private var timer: Timer?
    private let shownMedalKey = "lastShownMedal"

    private init() {}

    func show(medal: UserMedal, challengeId: String, duration: TimeInterval = 2.5) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let userId = ChallengeManager.shared.currentUser?.id else { return }

        let key = "medal_shown_\(userId)_\(medal.name)_\(challengeId)_\(medal.achievedDate.formatted(.iso8601))"

        if UserDefaults.standard.bool(forKey: key) {
            print("🔁 Médaille déjà affichée pour ce défi")
            return
        }

        UserDefaults.standard.set(true, forKey: key)

        self.currentMedal = medal
        self.isShown = true
        playFeedback()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.isShown = false
        }
    }

    private func playFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        AudioServicesPlaySystemSound(1057)
    }

    func dismiss() {
        self.isShown = false
        self.currentMedal = nil
        timer?.invalidate()
    }
}
