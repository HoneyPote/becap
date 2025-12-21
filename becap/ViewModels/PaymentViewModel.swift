//
//  PaymentViewModel.swift
//  becap
//
//  Simple view model to orchestrate Apple Pay purchases via PaymentHandler.
//

import Foundation
import PassKit

struct CartItem: Identifiable {
    let id = UUID()
    let name: String
    let price: Decimal

    var paymentSummaryItem: PKPaymentSummaryItem {
        PKPaymentSummaryItem(label: name, amount: NSDecimalNumber(decimal: price))
    }
}

final class PaymentViewModel: ObservableObject {
    @Published var cartItems: [CartItem] = []
    @Published var paymentSuccess: Bool = false

    private let paymentHandler = PaymentHandler()

    func pay() {
        let items = cartItems.map { $0.paymentSummaryItem }
        let total = totalSummaryItem(from: cartItems)

        paymentHandler.startPayment(products: items, total: total) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.cartItems.removeAll()
                    self?.paymentSuccess = true
                } else {
                    self?.paymentSuccess = false
                }
            }
        }
    }

    private func totalSummaryItem(from items: [CartItem]) -> PKPaymentSummaryItem {
        let totalAmount = items.reduce(Decimal.zero) { partialResult, item in
            partialResult + item.price
        }
        return PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(decimal: totalAmount))
    }
}
