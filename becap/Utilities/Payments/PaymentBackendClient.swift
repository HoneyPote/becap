//
//  PaymentBackendClient.swift
//  becap
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//
//  Calls Cloud Functions to create Stripe payment sessions. Uses Stripe Checkout URLs so
//  Apple Pay and card payments are handled by Stripe; Firestore enrollments are updated via webhook.

import Foundation
import FirebaseFunctions

struct PaymentSessionResponse: Codable {
    let clientSecret: String?
    let checkoutUrl: String?
    let message: String?
}

final class PaymentBackendClient {
    static let shared = PaymentBackendClient()

    private let functions: Functions

    init(functions: Functions = Functions.functions()) {
        self.functions = functions
    }

    func createPaymentSession(challengeId: String, userId: String, method: PaymentMethod) async throws -> PaymentSessionResponse {
        let payload: [String: Any] = [
            "challengeId": challengeId,
            "userId": userId,
            "method": method.rawValue
        ]

        let callable = functions.httpsCallable("createStripePaymentIntentForChallenge")
        let result = try await callable.call(payload)

        if let data = result.data as? [String: Any] {
            let clientSecret = data["clientSecret"] as? String
            let checkoutUrl = data["checkoutUrl"] as? String
            let message = data["message"] as? String
            return PaymentSessionResponse(clientSecret: clientSecret, checkoutUrl: checkoutUrl, message: message)
        }

        throw PaymentCoordinatorError.invalidResponse
    }
}
