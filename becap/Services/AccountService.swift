//
//  AccountService.swift
//  becap
//
//  Created by Victor Derveaux on 17/07/2025.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

enum FirestoreUserKeys {
    static let users = "users"
    static let email = "email"
    static let name = "name"
    static let createdAt = "createdAt"
}

enum AccountError: Error {
    case createUserError(String)
    case fetchUserError(String)
}

protocol AccountServiceProtocol {
    var currentUser: FirebaseAuth.User? { get }

    func login(email: String, password: String) async throws -> FirebaseAuth.User
    func register(email: String, password: String, name: String) async throws -> FirebaseAuth.User
    func signOut() throws
    func fetchUserDocument(uid: String) async throws -> DocumentSnapshot
}

class AccountService: AccountServiceProtocol {
    static let shared = AccountService()

    private let firebaseAuth: Auth
    private let firestoreDB: Firestore

    var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }

    init(firebaseAuth: Auth = Auth.auth(), firestoreDB: Firestore = Firestore.firestore()) {
        self.firebaseAuth = firebaseAuth
        self.firestoreDB = firestoreDB
    }
}

extension AccountService {
    func login(email: String, password: String) async throws -> FirebaseAuth.User {
        return try await firebaseAuth.signIn(withEmail: email, password: password).user
    }

    func register(email: String, password: String, name: String) async throws -> FirebaseAuth.User {
        let firebaseUser = try await firebaseAuth.createUser(withEmail: email, password: password).user
        try await createUserDocument(user: firebaseUser, name: name)
        return firebaseUser
    }

    func signOut() throws {
        try firebaseAuth.signOut()
    }

    func fetchUserDocument(uid: String) async throws -> DocumentSnapshot {
        do {
            return try await firestoreDB.collection("users").document(uid).getDocument()
        } catch {
            throw AccountError.fetchUserError(error.localizedDescription)
        }
    }

    // MARK: - Private functions
    private func createUserDocument(user: FirebaseAuth.User, name: String) async throws {
        guard let email = user.email else {
            throw AccountError.createUserError("Unable to create user, missing email.")
        }

        let ref = firestoreDB.collection(FirestoreUserKeys.users).document(user.uid)
        try await ref.setData([
            FirestoreUserKeys.email: email,
            FirestoreUserKeys.name: name,
            FirestoreUserKeys.createdAt: FieldValue.serverTimestamp()
        ])
    }

}
