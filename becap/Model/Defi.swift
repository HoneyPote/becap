//
//  Defi.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

// ChallengeApp/Models/Defi.swift

import Foundation

struct Defi: Identifiable, Codable, Hashable {
    var id = UUID()
    var nom: String
    var dateDebut: Date
    var duree: Int
    var participants: [String]
    var heureNotification: Date
}

struct PhotoDefi: Identifiable, Codable {
    var id = UUID()
    var defiId: UUID
    var date: Date
    var prenomAuteur: String
    var imagePath: String
}
