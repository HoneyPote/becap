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
}

extension AccountManager {
    func login(email: String, password: String) async throws -> User? {
        let firebaseUser = try await accountService.login(email: email, password: password)
        return try await updateCurrentUser(with: firebaseUser.uid)
    }

    func register(email: String, password: String, name: String) async throws -> User? {
        let firebaseUser = try await accountService.register(email: email, password: password, name: name)
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
