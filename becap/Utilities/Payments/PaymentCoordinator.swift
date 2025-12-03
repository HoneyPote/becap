//
//  PaymentCoordinator.swift
//  becap
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//
//  The coordinator now delegates payment validation to the backend (Stripe Checkout / PaymentIntent)
//  instead of marking success locally. It opens the provider flow and relies on Firestore enrollments
//  updated by webhooks to unlock challenges.

import Foundation
import SafariServices
import UIKit

enum PaymentFlowOutcome {
    case initiated
    case awaitingConfirmation
}

enum PaymentCoordinatorError: LocalizedError {
    case unavailable
    case missingMerchantId
    case presentationFailed
    case cancelled
    case backendFailure(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Le paiement n’est pas disponible sur cet appareil."
        case .missingMerchantId:
            return "Aucun identifiant marchand Apple Pay n’a été trouvé."
        case .presentationFailed:
            return "Impossible d’ouvrir le flux de paiement pour le moment."
        case .cancelled:
            return "Le paiement a été annulé."
        case .backendFailure(let reason):
            return reason
        case .invalidResponse:
            return "Réponse de paiement invalide."
        }
    }
}

final class PaymentCoordinator: NSObject {
    static let shared = PaymentCoordinator()

    private let backendClient: PaymentBackendClient
    private var safariController: SFSafariViewController?

    init(backendClient: PaymentBackendClient = .shared) {
        self.backendClient = backendClient
    }

    func startPayment(for challenge: Challenge,
                      userId: String,
                      method: PaymentMethod,
                      completion: @escaping (Result<PaymentFlowOutcome, PaymentCoordinatorError>) -> Void) {
        Task {
            do {
                let response = try await backendClient.createPaymentSession(challengeId: challenge.id, userId: userId, method: method)

                if let checkoutURL = response.checkoutUrl, let url = URL(string: checkoutURL) {
                    await presentSafari(for: url)
                    completion(.success(.initiated))
                    return
                }

                if response.message != nil {
                    completion(.failure(.backendFailure(response.message ?? "")))
                } else {
                    completion(.failure(.invalidResponse))
                }
            } catch {
                completion(.failure(.backendFailure(error.localizedDescription)))
            }
        }
    }

    private func presentSafari(for url: URL) async {
        await MainActor.run {
            let controller = SFSafariViewController(url: url)
            controller.dismissButtonStyle = .done
            safariController = controller

            guard let topController = UIApplication.shared.connectedScenes
                .compactMap({ scene in
                    (scene as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow })
                })
                .first?.rootViewController else { return }

            var presenter = topController
            while let presented = presenter.presentedViewController {
                presenter = presented
            }

            presenter.present(controller, animated: true)
        }
    }
}
