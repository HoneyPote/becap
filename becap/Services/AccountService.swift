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
    private let firebaseAuth = Auth.auth()
    private let firestoreDB = Firestore.firestore()

    private(set) var currentUser: FirebaseAuth.User? = Auth.auth().currentUser
}

extension AccountService {
    func login(email: String, password: String) async throws -> FirebaseAuth.User {
        do {
            return try await firebaseAuth.signIn(withEmail: email, password: password).user
        } catch let error {
            throw error
        }
    }

    func register(email: String, password: String, name: String) async throws -> FirebaseAuth.User {
        do {
            let result = try await firebaseAuth.createUser(withEmail: email, password: password)

            try await createUserDocument(user: result.user, name: name)

            return result.user
        } catch let error {
            throw error
        }
    }

    func signOut() throws {
        do {
            try firebaseAuth.signOut()
        } catch let error {
            throw error
        }
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

        let ref = firestoreDB.collection("users").document(user.uid)
        try await ref.setData([
            "email": email,
            "name": name,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

}
