//
//  UserModel.swift
//  becap
//
//  Created by Victor Derveaux on 20/07/2025.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var name: String
    var photoURL: String?
    var medals: [UserMedal]
    var participatingChallengesIds: [String]?
	var isInfluencer: Bool?
    /// Cloud-backed premium entitlement flag written by StoreKit sync.
    var premiumEntitlement: Bool?
}

struct UserMedal: Codable, Identifiable, Equatable {
    var id: String { name }
    let name: String
    let description: String
    let iconName: String
    let achievedDate: Date
    var challengeId: String
}
