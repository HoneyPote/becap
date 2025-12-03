//
//  PaymentConfiguration.swift
//  becap
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//

import Foundation
import PassKit

struct PaymentConfiguration {
    static let shared = PaymentConfiguration()

    let countryCode: String = "FR"
    let currencyCode: String = "EUR"
    let supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex, .cartesBancaires, .discover]

    var merchantIdentifier: String? {
        Bundle.main.object(forInfoDictionaryKey: "AppleMerchantIdentifier") as? String
    }

    func buildRequest(for challenge: Challenge, method: PaymentMethod) -> PKPaymentRequest? {
        guard let merchantIdentifier else { return nil }

        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantIdentifier
        request.supportedNetworks = supportedNetworks
        request.merchantCapabilities = .capability3DS
        request.countryCode = countryCode
        request.currencyCode = currencyCode
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: challenge.title, amount: challenge.paymentAmount),
            PKPaymentSummaryItem(label: "Becap", amount: challenge.paymentAmount)
        ]

        if method == .card {
            request.requiredBillingContactFields = [.name, .postalAddress]
        }

        return request
    }
}

enum PaymentMethod: String {
    case applePay = "apple_pay"
    case card = "card"
}
