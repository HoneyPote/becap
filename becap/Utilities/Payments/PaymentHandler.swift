//
//  PaymentHandler.swift
//  becap
//
//  Manages Apple Pay transactions using PKPaymentAuthorizationController.
//

import Foundation
import PassKit

final class PaymentHandler: NSObject {
    static let supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard]

    private var paymentController: PKPaymentAuthorizationController?
    private var completionHandler: ((Bool) -> Void)?
    private var paymentAuthorized = false

    func startPayment(products: [PKPaymentSummaryItem],
                      total: PKPaymentSummaryItem,
                      completionHandler: @escaping (Bool) -> Void) {
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = "merchant.io.designcode.sweatershopdemo"
        paymentRequest.countryCode = "US"
        paymentRequest.currencyCode = "USD"
        paymentRequest.supportedNetworks = Self.supportedNetworks
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.requiredShippingContactFields = [.postalAddress, .name]
        paymentRequest.paymentSummaryItems = products + [total]
        paymentRequest.shippingMethods = [shippingMethodCalculator()]

        paymentAuthorized = false
        self.completionHandler = completionHandler

        paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController?.delegate = self
        paymentController?.present { [weak self] presented in
            guard let self else { return }
            if !presented {
                self.completionHandler?(false)
                self.completionHandler = nil
            }
        }
    }

    private func shippingMethodCalculator() -> PKShippingMethod {
        let method = PKShippingMethod(label: "Livraison standard", amount: NSDecimalNumber(string: "0.00"))
        method.identifier = "standard"
        method.detail = "Livraison sous 3 à 5 jours ouvrés"
        return method
    }
}

extension PaymentHandler: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didAuthorizePayment payment: PKPayment,
                                        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        paymentAuthorized = true
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss { [weak self] in
            guard let self else { return }
            self.completionHandler?(self.paymentAuthorized)
            self.completionHandler = nil
            self.paymentController = nil
        }
    }
}
