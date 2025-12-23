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
