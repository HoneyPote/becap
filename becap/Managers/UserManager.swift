//
//  UserManager.swift
//  becap
//
//  Created by Victor Derveaux on 22/07/2025.
//

import Foundation

protocol UserManagerProtocol {
    var currentUser: User? { get }

    func saveUser(user: User?)
    func resetUser()
}

// Singleton
final class UserManager: UserManagerProtocol, ObservableObject {
    static let shared = UserManager()

    @Published private(set) var currentUser: User?

    private init() {}

    func saveUser(user: User?) {
        self.currentUser = user
    }

    func resetUser() {
        self.currentUser = nil
    }
}
