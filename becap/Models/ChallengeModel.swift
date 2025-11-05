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
    var jokerConfiguration: ChallengeJokerConfiguration?

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
    var jokerState: PhotoJokerState?

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

struct PhotoDeepLink: Equatable {
    let challengeId: String
    let photoId: String
}

import SwiftUI

final class DeepLinkRouter: ObservableObject {
    @Published var pendingJoinCode: String? = nil
    @Published var showJoinSheet: Bool = false
    @Published var pendingCalendarChallengeId: String? = nil
    @Published var pendingPhotoLink: PhotoDeepLink? = nil

    // Appelle ceci depuis .onOpenURL
    func handle(url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              comps.scheme?.lowercased() == "becap" else { return }

        let host = comps.host?.lowercased()

        switch host {
        case "join":
            let code = comps.queryItems?.first(where: { $0.name == "code" })?.value
            let challengeId = comps.queryItems?.first(where: { $0.name == "challengeId" })?.value
            DispatchQueue.main.async {
                if let challengeId, !challengeId.isEmpty {
                    self.pendingCalendarChallengeId = challengeId
                    self.showJoinSheet = false
                }

                if let code, !code.isEmpty {
                    self.pendingJoinCode = code
                    if challengeId == nil {
                        self.showJoinSheet = true
                    }
                }
            }

        case "photo":
            let challengeId = comps.queryItems?.first(where: { $0.name == "challengeId" })?.value
            let photoId = comps.queryItems?.first(where: { $0.name == "photoId" })?.value

            guard let challengeId, !challengeId.isEmpty,
                  let photoId, !photoId.isEmpty else { return }

            DispatchQueue.main.async {
                // Définir d'abord la cible photo pour que les observateurs disposent
                // de l'identifiant avant que le challenge ne déclenche la navigation.
                self.pendingPhotoLink = PhotoDeepLink(challengeId: challengeId, photoId: photoId)
                self.pendingCalendarChallengeId = challengeId
                self.showJoinSheet = false
            }

        default:
            break
        }
    }

    func clearJoin() {
        pendingJoinCode = nil
        showJoinSheet = false
    }

    func clearChallengeNavigation() {
        pendingCalendarChallengeId = nil
    }

    func clearPhotoNavigation() {
        pendingPhotoLink = nil
    }
}
