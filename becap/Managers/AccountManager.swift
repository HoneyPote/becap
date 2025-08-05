//
//  AccountManager.swift
//  becap
//
//  Created by Victor Derveaux on 21/07/2025.
//

import Foundation
import OneSignalFramework
import Firebase

protocol AccountManagerProtocol {
    func login(email: String, password: String) async throws -> User?
    func register(email: String, password: String, name: String) async throws -> User?
    func updateCurrentUser(with uid: String) async throws -> User?
    func signOut() throws
    func fetchUser(uid: String) async throws -> User?
}

class AccountManager: AccountManagerProtocol {
    private let accountService: AccountServiceProtocol
    private let userManager: UserManagerProtocol

    init(userManager: UserManagerProtocol = UserManager.shared,
         accountService: AccountServiceProtocol = AccountService()) {
        self.userManager = userManager
        self.accountService = accountService
    }

    func updateCurrentUser(with uid: String) async throws -> User? {
        let user = try await self.fetchUser(uid: uid)

        userManager.saveUser(user: user)
        return user
    }



    func updateOneSignalPlayerId(for userId: String) {
        if let playerId = OneSignal.User.pushSubscription.id, !playerId.isEmpty {
            Firestore.firestore().collection("users").document(userId).setData([
                "onesignalPlayerId": playerId
            ], merge: true)
            print("✅ OneSignal playerId enregistré : \(playerId)")
        } else {
            print("❌ Pas de playerId OneSignal trouvé.")
        }
    }
}

extension AccountManager {
    func login(email: String, password: String) async throws -> User? {
        let firebaseUser = try await accountService.login(email: email, password: password)
        updateOneSignalPlayerId(for: firebaseUser.uid)
        return try await updateCurrentUser(with: firebaseUser.uid)
    }

    func register(email: String, password: String, name: String) async throws -> User? {
        let firebaseUser = try await accountService.register(email: email, password: password, name: name)
        updateOneSignalPlayerId(for: firebaseUser.uid)
        return try await updateCurrentUser(with: firebaseUser.uid)
    }

    func signOut() throws {
        try accountService.signOut()

        userManager.resetUser()
    }

    func fetchUser(uid: String) async throws -> User? {
        do {

            return try await accountService.fetchUserDocument(uid: uid).data(as: User.self)
        } catch {
            throw AccountError.fetchUserError(error.localizedDescription)
        }
    }
}
