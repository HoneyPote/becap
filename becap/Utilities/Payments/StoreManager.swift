//
//  StoreManager.swift
//  becap
//
//  In-App Purchase coordinator using StoreKit 2.
//  TODO App Store Connect: create products with the same identifiers.
//  ⚙️ Enable the "In-App Purchase" capability in the main target.
//  💡 For local StoreKit tests, add a StoreKit.storekit file to the project
//  and select it in the scheme's Run configuration.
//  🧪 Sandbox: sign out of App Store on device/simulator, sign in with a
//  sandbox tester account, then purchase through this paywall.
//

import Foundation
import StoreKit
import FirebaseFirestore

@MainActor
final class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isPremium: Bool = false {
        didSet {
            guard isPremium != oldValue else { return }
            updateHasPremiumAccess()
            Task { await syncPremiumFlagIfNeeded() }
        }
    }
    @Published private(set) var hasPremiumAccess: Bool = false
    @Published private(set) var isManuallyLocked: Bool = false

    private var updateListenerTask: Task<Void, Never>?
    private let manualLockKey = "becap.premium.manualLock"

    init() {
        isManuallyLocked = UserDefaults.standard.bool(forKey: manualLockKey)
        updateHasPremiumAccess()
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

    func buy(_ product: Product) async -> PurchaseOutcome {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                guard transaction.revocationDate == nil else {
                    await transaction.finish()
                    return .failed(StoreKitError.revoked)
                }

                await transaction.finish()
                await refreshEntitlements()
                return .success
            case .userCancelled:
                debugPrint("ℹ️ Purchase cancelled by user for product: \(product.id)")
                return .cancelled
            case .pending:
                debugPrint("⏳ Purchase pending for product: \(product.id)")
                return .pending
            default:
                return .failed(StoreKitError.unknown)
            }
        } catch {
            debugPrint("❌ Purchase failed for product \(product.id):", error.localizedDescription)
            return .failed(error)
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
            guard transaction.revocationDate == nil else { continue }

            if IAPProductIDs.allProductIds.contains(transaction.productID) {
                hasPremium = true
            }
        }

        if isPremium != hasPremium {
            isPremium = hasPremium
            debugPrint("⭐️ Premium entitlement updated: \(hasPremium)")
        } else {
            updateHasPremiumAccess()
        }
    }

    func setManualLock(_ enabled: Bool) {
        guard enabled != isManuallyLocked else { return }
        isManuallyLocked = enabled
        UserDefaults.standard.set(enabled, forKey: manualLockKey)
        updateHasPremiumAccess()
        debugPrint(enabled ? "🔒 Premium manually locked for testing" : "🔓 Manual lock cleared")
    }
}

private extension StoreManager {
    func startListeningForTransactions() {
        updateListenerTask = Task { [weak self] in
            guard let self else { return }

            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    guard transaction.revocationDate == nil else {
                        await transaction.finish()
                        continue
                    }

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

    func updateHasPremiumAccess() {
        hasPremiumAccess = isPremium && !isManuallyLocked
    }
}

private enum StoreKitError: Error {
    case failedVerification
    case revoked
    case unknown
}

enum PurchaseOutcome {
    case success
    case cancelled
    case pending
    case failed(Error)
}
