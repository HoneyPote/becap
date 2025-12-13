//
//  StoreManager.swift
//  becap
//
//  In-App Purchase coordinator using StoreKit 2.
//  TODO App Store Connect: create products with the same identifiers.
//  ⚙️ Enable the "In-App Purchase" capability in the main target.
//  💡 For local StoreKit tests, add a StoreKit.storekit file to the project
//  and select it in the scheme's Run configuration.
//

import Foundation
import StoreKit
import FirebaseFirestore

@MainActor
final class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isPremium: Bool = false {
        didSet {
            Task { await syncPremiumFlagIfNeeded() }
        }
    }

    private var updateListenerTask: Task<Void, Never>?

    init() {
        startListeningForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        do {
            let fetchedProducts = try await Product.products(for: Array(IAPProductIDs.allProductIds))
            products = fetchedProducts.sorted { $0.price < $1.price }
            debugPrint("🛒 Loaded StoreKit products:", products.map(\.id))
        } catch {
            debugPrint("❌ Failed to load products:", error.localizedDescription)
        }
    }

    func buy(_ product: Product) async {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled:
                debugPrint("ℹ️ Purchase cancelled by user for product: \(product.id)")
            case .pending:
                debugPrint("⏳ Purchase pending for product: \(product.id)")
            default:
                break
            }
        } catch {
            debugPrint("❌ Purchase failed for product \(product.id):", error.localizedDescription)
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            debugPrint("✅ Restore requested")
        } catch {
            debugPrint("❌ Restore failed:", error.localizedDescription)
        }
    }

    func refreshEntitlements() async {
        var hasPremium = false

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }

            if IAPProductIDs.allProductIds.contains(transaction.productID) {
                hasPremium = true
            }
        }

        if isPremium != hasPremium {
            isPremium = hasPremium
            debugPrint("⭐️ Premium entitlement updated: \(hasPremium)")
        }
    }
}

private extension StoreManager {
    func startListeningForTransactions() {
        updateListenerTask = Task { [weak self] in
            guard let self else { return }

            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await transaction.finish()
                    await refreshEntitlements()
                } catch {
                    debugPrint("❌ Transaction verification failed:", error.localizedDescription)
                }
            }
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let signedType):
            return signedType
        }
    }

    func syncPremiumFlagIfNeeded() async {
        guard let userId = UserManager.shared.currentUser?.id else { return }

        do {
            try await Firestore.firestore().collection("users").document(userId).setData([
                "premiumEntitlement": isPremium,
                "premiumSource": "storekit"
            ], merge: true)
            debugPrint("☁️ Synced premium entitlement to Firestore: \(isPremium)")
        } catch {
            debugPrint("⚠️ Unable to sync premium flag:", error.localizedDescription)
        }
    }
}

private enum StoreKitError: Error {
    case failedVerification
}
