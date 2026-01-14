import UIKit

enum Haptics {
    static func lightTap() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred(intensity: 0.8)
    }

    static func selection() {
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.selectionChanged()
    }

    static func success() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(.success)
    }
}
