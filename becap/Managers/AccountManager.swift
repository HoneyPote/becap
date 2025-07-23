//
//  AccountManager.swift
//  becap
//
//  Created by Victor Derveaux on 21/07/2025.
//

import Foundation

protocol AccountManagerProtocol {
    func login(email: String, password: String) async throws -> User?
    func register(email: String, password: String, name: String) async throws -> User?
    func signOut() throws
    func fetchUser(uid: String) async throws -> User?
}

class AccountManager: AccountManagerProtocol {
    private let accountService: AccountServiceProtocol = AccountService()
}

extension AccountManager {
    func login(email: String, password: String) async throws -> User? {
        do {
            let firebaseUser = try await accountService.login(email: email, password: password)
            let user = try await self.fetchUser(uid: firebaseUser.uid)

            UserManager.shared.currentUser = user
            return user
        } catch let error {
            throw error
        }
    }

    func register(email: String, password: String, name: String) async throws -> User? {
        do {
            let firebaseUser = try await accountService.register(email: email, password: password, name: name)
            let user = try await self.fetchUser(uid: firebaseUser.uid)

            UserManager.shared.currentUser = user
            return user
        } catch let error {
            throw error
        }
    }

    func signOut() throws {
        do {
            try accountService.signOut()
            UserManager.shared.currentUser = nil
        } catch let error {
            throw error
        }
    }

    func fetchUser(uid: String) async throws -> User? {
        do {
            return try await accountService.fetchUserDocument(uid: uid).data(as: User.self)
        } catch {
            throw AccountError.fetchUserError(error.localizedDescription)
        }
    }
}
