//
//  PaymentCoordinator.swift
//  becap
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//

import Foundation
import PassKit

enum PaymentCoordinatorError: LocalizedError {
    case unavailable
    case missingMerchantId
    case presentationFailed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Apple Pay n’est pas disponible sur cet appareil."
        case .missingMerchantId:
            return "Aucun identifiant marchand Apple Pay n’a été trouvé."
        case .presentationFailed:
            return "Impossible d’ouvrir Apple Pay pour le moment."
        case .cancelled:
            return "Le paiement a été annulé."
        }
    }
}

final class PaymentCoordinator: NSObject {
    static let shared = PaymentCoordinator()

    private var paymentController: PKPaymentAuthorizationController?
    private var completion: ((Result<Void, PaymentCoordinatorError>) -> Void)?
    private var didAuthorizePayment = false

    func canMakePayments() -> Bool {
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: PaymentConfiguration.shared.supportedNetworks)
    }

    func startPayment(for challenge: Challenge,
                      method: PaymentMethod,
                      completion: @escaping (Result<Void, PaymentCoordinatorError>) -> Void) {
        guard canMakePayments() else {
            completion(.failure(.unavailable))
            return
        }

        guard let request = PaymentConfiguration.shared.buildRequest(for: challenge, method: method) else {
            completion(.failure(.missingMerchantId))
            return
        }

        self.completion = completion
        self.didAuthorizePayment = false

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self
        self.paymentController = controller

        controller.present { [weak self] presented in
            guard let self else { return }
            if !presented {
                completion(.failure(.presentationFailed))
            }
        }
    }
}

extension PaymentCoordinator: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didAuthorizePayment payment: PKPayment,
                                        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        didAuthorizePayment = true
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        self.completion?(.success(()))
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss { [weak self] in
            guard let self else { return }
            if !self.didAuthorizePayment {
                self.completion?(.failure(.cancelled))
            }
            self.completion = nil
            self.paymentController = nil
        }
    }
}
