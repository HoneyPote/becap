//
//  StripePaymentService.swift
//  becap
//
//  Created for integrating Stripe PaymentSheet.
//

import Foundation
import UIKit
import StripePaymentSheet

struct PaymentSheetConfigResponse: Decodable {
    let paymentIntentClientSecret: String
    let ephemeralKeySecret: String
    let customerId: String
    let publishableKey: String
}

/// A lightweight service that retrieves PaymentSheet configuration from Cloud Functions
/// and prepares a `PaymentSheet` instance ready to present.
@MainActor
final class StripePaymentService: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    private let functionsURL = URL(string: "https://us-central1-honeypote-becap.cloudfunctions.net/createPaymentSheet")!
    private let merchantDisplayName = "Becap"
    private let applePayMerchantId: String? = nil // Provide your Apple Pay merchant ID when available.

    /// Fetches PaymentSheet configuration from the backend and initializes Stripe with the publishable key.
    func preparePaymentSheet(userId: String, itemId: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        var request = URLRequest(url: functionsURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId,
            "itemId": itemId ?? "premium_challenge"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard
                let httpResponse = response as? HTTPURLResponse,
                let data = data,
                (200..<300).contains(httpResponse.statusCode)
            else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let backendError = NSError(domain: "StripePaymentService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare payment (status: \(statusCode))."])
                DispatchQueue.main.async {
                    completion(.failure(backendError))
                }
                return
            }

            do {
                let config = try JSONDecoder().decode(PaymentSheetConfigResponse.self, from: data)
                DispatchQueue.main.async {
                    self.configurePaymentSheet(with: config)
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    /// Presents the configured PaymentSheet from the given view controller.
    func presentPaymentSheet(from presentingViewController: UIViewController, completion: @escaping (PaymentSheetResult) -> Void) {
        guard let paymentSheet = paymentSheet else {
            completion(.failed(error: NSError(domain: "StripePaymentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "PaymentSheet not ready."])) )
            return
        }

        paymentSheet.present(from: presentingViewController) { result in
            completion(result)
        }
    }

    // MARK: - Private helpers
    private func configurePaymentSheet(with response: PaymentSheetConfigResponse) {
        STPAPIClient.shared.publishableKey = response.publishableKey

        let configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = merchantDisplayName
        configuration.customer = .init(id: response.customerId, ephemeralKeySecret: response.ephemeralKeySecret)
        configuration.returnURL = "becap://stripe-redirect"

        if let applePayMerchantId {
            configuration.applePay = .init(merchantId: applePayMerchantId)
        }

        paymentSheet = PaymentSheet(paymentIntentClientSecret: response.paymentIntentClientSecret, configuration: configuration)
    }
}
