//
//  IAPProductIDs.swift
//  becap
//
//  Product identifiers for StoreKit 2 purchases.
//  TODO App Store Connect: create products with the same identifiers.
//

import Foundation

enum IAPProductIDs {
    static let premiumMonthly = "becap_premium_monthly"
    static let premiumUnlock = "becap_premium_unlock"

    static let allProductIds: Set<String> = [
        IAPProductIDs.premiumMonthly,
        IAPProductIDs.premiumUnlock
    ]
}
