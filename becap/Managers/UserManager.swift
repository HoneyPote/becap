//
//  UserManager.swift
//  becap
//
//  Created by Victor Derveaux on 22/07/2025.
//

import Foundation

// Singleton
final class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var currentUser: User?

    private init() {}
    
    func saveUser (user: User) {
        self.currentUser = user
    }
    
    func resetUser () {
        self.currentUser = nil
    }
}
