//
//  StoreManager.swift
//  becap
//
//  StoreKit 2 manager supporting:
//  - Global premium subscription (access to ALL premium challenges)
//  - Per-challenge unlock (one-time IAP per premium challenge)
//  - Manual lock toggle for testing
//
//  Requirements:
//  - In-App Purchase capability enabled
//  - Products created in App Store Connect with matching product IDs
//  - Optional: StoreKit Configuration file for local testing
//

import Foundation
import StoreKit
import FirebaseFirestore

@MainActor
final class StoreManager: ObservableObject {

    // MARK: - Published state

    /// All StoreKit products loaded (global + per-challenge when requested).
    @Published private(set) var products: [Product] = []
    /// Backward-compat alias (ancien nom utilisé partout dans l’app)
    var hasPremiumAccess: Bool { hasGlobalPremiumAccess }
    /// Ancien nom
    var isPremium: Bool { hasGlobalPremiumEntitlement }

    /// Raw entitlement state for global premium (subscription / non-consumable "all access").
    @Published private(set) var hasGlobalPremiumEntitlement: Bool = false {
        didSet {
            guard hasGlobalPremiumEntitlement != oldValue else { return }
            updateHasGlobalPremiumAccess()
            Task { await syncGlobalPremiumFlagIfNeeded() }
        }
    }

    /// Effective global premium after applying manual lock.
    @Published private(set) var hasGlobalPremiumAccess: Bool = false

    /// Local-only toggle so testers can relock premium without touching entitlements/Firestore.
    @Published private(set) var isManuallyLocked: Bool = false

    /// Locally persisted set of unlocked premium challenges (one-time purchases).
    @Published private(set) var unlockedChallengeIds: Set<String> = []
    @Published private(set) var unlockedProductIds: Set<String> = []

    func isProductUnlocked(_ productId: String?) -> Bool {
        guard let productId, !productId.isEmpty else { return false }
        return unlockedProductIds.contains(productId)
    }

    /// Abonnement global (mensuel / annuel) -> accès à tout

    // MARK: - IDs

    /// Global premium product IDs (subscription + optional lifetime unlock).
    /// ✅ Must exist in App Store Connect.
    private let globalProductIds: Set<String> = [
        IAPProductIDs.premiumMonthly,
        IAPProductIDs.premiumUnlock
    ]

    /// UserDefaults keys
    private let manualLockKey = "becap.premium.manualLock"
    private let unlockedChallengesKey = "becap.premium.unlockedChallenges"

    // MARK: - Internal

    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - Init / Deinit

    init() {
        isManuallyLocked = UserDefaults.standard.bool(forKey: manualLockKey)
        unlockedChallengeIds = Set(UserDefaults.standard.stringArray(forKey: unlockedChallengesKey) ?? [])
        updateHasGlobalPremiumAccess()
        startListeningForTransactions()
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Public API (Loading)

    /// Loads only global products (subscription + lifetime unlock).
    func loadGlobalProducts() async {
        await loadProducts(productIds: globalProductIds)
    }

    /// Loads products for global + a set of per-challenge product IDs.
    /// Use this when presenting a specific challenge paywall.
    func loadProducts(global: Bool = true, perChallengeIds: Set<String> = []) async {
        var ids = Set<String>()
        if global { ids.formUnion(globalProductIds) }
        ids.formUnion(perChallengeIds)
        await loadProducts(productIds: ids)
    }

    private func loadProducts(productIds: Set<String>) async {
        guard !productIds.isEmpty else {
            products = []
            return
        }

        do {
            let fetched = try await Product.products(for: Array(productIds))
            // Keep deterministic order: by price then by id
            products = fetched.sorted {
                if $0.price == $1.price { return $0.id < $1.id }
                return $0.price < $1.price
            }
            debugPrint("🛒 Loaded StoreKit products:", products.map(\.id))
        } catch {
            debugPrint("❌ Failed to load StoreKit products:", error.localizedDescription)
            products = []
        }
    }

    // MARK: - Public API (Purchase)

    /// Purchase any StoreKit product (global or per-challenge).
    /// If it's a per-challenge product, you should call `unlockChallengeIdLocally(...)`
    /// after success, or call `purchaseAndUnlockChallenge(...)` below.
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

                // Finish then refresh entitlements
                await transaction.finish()
                await refreshEntitlements()

                return .success

            case .userCancelled:
                debugPrint("ℹ️ Purchase cancelled by user for product:", product.id)
                return .cancelled

            case .pending:
                debugPrint("⏳ Purchase pending for product:", product.id)
                return .pending

            default:
                return .failed(StoreKitError.unknown)
            }
        } catch {
            debugPrint("❌ Purchase failed for product \(product.id):", error.localizedDescription)
            return .failed(error)
        }
    }

    /// Convenience for the "buy one premium challenge" flow.
    /// - You must pass the per-challenge productId created in App Store Connect.
    func purchaseAndUnlockChallenge(challengeId: String, productId: String) async -> PurchaseOutcome {
        do {
            let fetched = try await Product.products(for: [productId])
            guard let product = fetched.first else {
                return .failed(StoreKitError.productNotFound)
            }

            let outcome = await buy(product)
            if case .success = outcome {
                unlockChallengeIdLocally(challengeId)
            }
            return outcome
        } catch {
            return .failed(error)
        }
    }

    // MARK: - Restore / Entitlements

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            debugPrint("✅ Restore requested")
        } catch {
            debugPrint("❌ Restore failed:", error.localizedDescription)
        }
    }

    /// Refreshes global premium entitlements based on StoreKit current entitlements.
    func refreshEntitlements() async {
        var hasGlobal = false

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            guard transaction.revocationDate == nil else { continue }

            if globalProductIds.contains(transaction.productID) {
                hasGlobal = true
            }
        }

        if hasGlobalPremiumEntitlement != hasGlobal {
            hasGlobalPremiumEntitlement = hasGlobal
            debugPrint("⭐️ Global premium entitlement updated:", hasGlobal)
        } else {
            updateHasGlobalPremiumAccess()
        }
    }

    // MARK: - Access checks

    /// Returns true if the user can access this premium challenge:
    /// - global premium access OR
    /// - this specific challenge has been unlocked
    func canAccessPremiumChallenge(_ challenge: Challenge) -> Bool {
        // If not premium, always accessible
        guard (challenge.isPremium ?? false) else { return true }
        return hasGlobalPremiumAccess || unlockedChallengeIds.contains(challenge.id)
    }

    /// Returns true if the challenge is unlocked *specifically* (not via global subscription).
    func isChallengeUnlocked(_ challenge: Challenge) -> Bool {
        unlockedChallengeIds.contains(challenge.id)
    }

    // MARK: - Local unlock persistence

    func unlockChallenge(_ challenge: Challenge) {
        unlockChallengeIdLocally(challenge.id)
    }

    func unlockChallengeIdLocally(_ challengeId: String) {
        guard !challengeId.isEmpty else { return }
        unlockedChallengeIds.insert(challengeId)
        persistUnlockedChallengeIds()
        debugPrint("🔓 Unlocked premium challenge locally:", challengeId)
    }

    func lockChallengeForTesting(_ challenge: Challenge) {
        unlockedChallengeIds.remove(challenge.id)
        persistUnlockedChallengeIds()
        debugPrint("🔒 Relocked premium challenge locally:", challenge.id)
    }

    func resetAllUnlockedChallengesForTesting() {
        unlockedChallengeIds.removeAll()
        persistUnlockedChallengeIds()
        debugPrint("🧹 Cleared all local unlocked premium challenges")
    }

    private func persistUnlockedChallengeIds() {
        UserDefaults.standard.set(Array(unlockedChallengeIds), forKey: unlockedChallengesKey)
    }

    // MARK: - Manual lock (testing)

    func setManualLock(_ enabled: Bool) {
        guard enabled != isManuallyLocked else { return }
        isManuallyLocked = enabled
        UserDefaults.standard.set(enabled, forKey: manualLockKey)
        updateHasGlobalPremiumAccess()
        debugPrint(enabled ? "🔒 Global premium manually locked for testing" : "🔓 Manual lock cleared")
    }
}

// MARK: - Transaction listening / helpers

private extension StoreManager {

    func startListeningForTransactions() {
        transactionListenerTask = Task { [weak self] in
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

    func updateHasGlobalPremiumAccess() {
        // global premium only depends on entitlement + manual lock
        hasGlobalPremiumAccess = hasGlobalPremiumEntitlement && !isManuallyLocked
    }

    /// Optional: sync ONLY the global premium entitlement to Firestore.
    /// Per-challenge unlocks are local here (simple). You can sync them later if you want.
    func syncGlobalPremiumFlagIfNeeded() async {
        guard let userId = UserManager.shared.currentUser?.id else { return }

        do {
            try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .setData([
                    "premiumEntitlement": hasGlobalPremiumEntitlement,
                    "premiumSource": "storekit"
                ], merge: true)

            debugPrint("☁️ Synced global premium entitlement to Firestore:", hasGlobalPremiumEntitlement)
        } catch {
            debugPrint("⚠️ Unable to sync global premium flag:", error.localizedDescription)
        }
    }
}

// MARK: - Errors / Outcome

private enum StoreKitError: Error {
    case failedVerification
    case revoked
    case unknown
    case productNotFound
}

enum PurchaseOutcome {
    case success
    case cancelled
    case pending
    case failed(Error)
}
