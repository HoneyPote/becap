//
//  ChallengeModel.swift
//  becap
//
//  Created by Victor Derveaux on 23/07/2025.
//

import Foundation
import FirebaseFirestore

struct Challenge: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var duration: Int
    var startDate: Date
    var creatorUID: String
    var participantUids: [String]
    var status: String // "active", "finished"
    var notificationsConfig: [ChallengeNotification]?
    var code: String? // <- Ajouté ici

    // Hashable synthétique via les propriétés, mais tu peux aussi customiser si besoin :
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
    }

    static func ==(lhs: Challenge, rhs: Challenge) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}

struct ChallengePhoto: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var challengeId: String?             // ID du défi (parent) // TODO: Passer en non optionnel lorsque bdd cleanée
    var authorUid: String                // UID Firebase de l'auteur
    var authorName: String               // Nom ou prénom affiché
    var imageUrl: String                 // URL Cloud Storage de la photo
    var description: String?             // Description optionnelle (légende)
    var date: Date                       // Date de prise ou de soumission
    var createdAt: Date                  // Date de création Firestore (souvent == date)

    var likes: [String]? // <--- AJOUTE CE CHAMP ! (optional pour backward compatibilité)

    // Pour Hashable automatique
    static func == (lhs: ChallengePhoto, rhs: ChallengePhoto) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ChallengeNotification: Codable {
    var dayIndex: Int
    var times: [Date] // Format "HH:mm" ou utiliser Date si tu préfères
}
