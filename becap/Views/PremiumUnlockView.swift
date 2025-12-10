//
//  PremiumUnlockView.swift
//  becap
//
//  Demonstrates how to present Stripe PaymentSheet to unlock premium challenges.
//

import SwiftUI
import UIKit
import StripePaymentSheet

struct PremiumUnlockView: View {
    @StateObject private var paymentService = StripePaymentService()
    @State private var isLoading = false
    @State private var statusMessage: String?

    let challengeId: String
    let userId: String
    var onUnlocked: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Text("Unlock premium challenges with one tap")
                .font(.headline)
                .multilineTextAlignment(.center)

            if let statusMessage {
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: startPaymentFlow) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Unlock Premium Challenge")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(isLoading)
        }
        .padding()
    }

    private func startPaymentFlow() {
        guard let presentingViewController = UIApplication.shared.presentingViewController else {
            statusMessage = "Unable to find a view controller to present the payment sheet."
            return
        }

        isLoading = true
        statusMessage = nil

        paymentService.preparePaymentSheet(userId: userId, itemId: challengeId) { result in
            isLoading = false

            switch result {
            case .success:
                paymentService.presentPaymentSheet(from: presentingViewController) { paymentResult in
                    switch paymentResult {
                    case .completed:
                        statusMessage = "Payment completed!"
                        onUnlocked?()
                    case .canceled:
                        statusMessage = "Payment canceled."
                    case .failed(let error):
                        statusMessage = "Payment failed: \(error.localizedDescription)"
                    }
                }
            case .failure(let error):
                statusMessage = "Could not start payment: \(error.localizedDescription)"
            }
        }
    }
}

private extension UIApplication {
    /// Returns the top-most presented view controller that can present the PaymentSheet.
    var presentingViewController: UIViewController? {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }

        var topController = root
        while let presented = topController.presentedViewController {
            topController = presented
        }

        return topController
    }
}

struct PremiumUnlockView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumUnlockView(challengeId: "challenge_123", userId: "user_123")
    }
}
