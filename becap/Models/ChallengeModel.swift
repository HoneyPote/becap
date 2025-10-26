//
//  ChallengeModel.swift
//  becap
//
//  Created by Victor Derveaux on 23/07/2025.
//

import Foundation
import FirebaseFirestore

enum ChallengeStatus: String {
    case active = "En cours"
    case finished = "Termniné"
}

struct Challenge: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var duration: Int
    var startDate: Date
    var creatorUID: String
    var participantUids: [String]
    var notificationsConfig: [ChallengeNotification]?
    var code: String?

    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: duration, to: startDate) ?? startDate
    }

    var status: ChallengeStatus {
        Date() > endDate ? .finished : .active
    }


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



enum DeepLink {
    case join(code: String, challengeId: String?)
}

import SwiftUI

final class DeepLinkRouter: ObservableObject {
    @Published var pendingJoinCode: String? = nil
    @Published var showJoinSheet: Bool = false

    // Appelle ceci depuis .onOpenURL
    func handle(url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        // Ex: becap://join?code=123456
        if comps.scheme?.lowercased() == "becap",
           comps.host?.lowercased() == "join" {
            let code = comps.queryItems?.first(where: { $0.name == "code" })?.value
            DispatchQueue.main.async {
                self.pendingJoinCode = code
                self.showJoinSheet = true
            }
        }
    }

    func clearJoin() {
        pendingJoinCode = nil
        showJoinSheet = false
    }
}
