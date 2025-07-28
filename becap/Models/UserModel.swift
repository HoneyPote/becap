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
    var medals: [UserMedal]?
    var joinedChallenges: [String]?
}

struct UserMedal: Codable, Identifiable {
    var id: String { name }
    let name: String
    let description: String
    let iconName: String
    let achievedDate: Date
}

struct ParticipantProgress: Identifiable, Codable {
    var id: String
    var joinedDate: Date
    var validatedDays: [Date]
    var medals: [UserMedal]
    var currentStreak: Int
}
