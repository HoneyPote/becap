//
//  RewardService.swift
//  becap
//
//  Created by Adam Mabrouki on 26/07/2025.
//

import Foundation
import FirebaseFirestore

class RewardService {
    static let shared = RewardService()

    let db = Firestore.firestore()

    private init() {}

    func assignCreationMedals(to userId: String, createdCount: Int) async {
        let userRef = db.collection("users").document(userId)

        do {
            let snapshot = try await userRef.getDocument()
            var user = try snapshot.data(as: User.self)
            var medals = user.medals
            var newMedals: [UserMedal] = []

            if medals.first(where: { $0.name == "🛠 Premier défi" }) == nil {
                let definition = MedalCatalog.creationDefinitions.first { $0.name == "🛠 Premier défi" }
                newMedals.append(UserMedal(
                    name: definition?.name ?? "🛠 Premier défi",
                    description: definition?.description ?? "Tu as créé ton premier défi !",
                    iconName: definition?.iconName ?? "hammer",
                    achievedDate: Date(),
                    challengeId: "creation"
                ))
            }

            if createdCount >= 3,
               medals.first(where: { $0.name == "👷‍♂️ Builder" }) == nil {
                let definition = MedalCatalog.creationDefinitions.first { $0.name == "👷‍♂️ Builder" }
                newMedals.append(UserMedal(
                    name: definition?.name ?? "👷‍♂️ Builder",
                    description: definition?.description ?? "3 défis créés",
                    iconName: definition?.iconName ?? "person.3",
                    achievedDate: Date(),
                    challengeId: "builder"
                ))
            }

            if !newMedals.isEmpty {
                medals.append(contentsOf: newMedals)
                user.medals = medals
                try userRef.setData(from: user)
                print("✅ Médailles de création ajoutées ", newMedals.map(\.name))
            }
        } catch {
            print("❌ assignCreationMedals > Erreur: \(error)")
        }
    }

    func addMedals(to userId: String, medals: [UserMedal]) async {
        let userRef = db.collection("users").document(userId)

        do {
            let snapshot = try await userRef.getDocument()
            var user = try snapshot.data(as: User.self)
            var userMedals = user.medals
            for medal in medals {
                if !userMedals.contains(where: { $0.name == medal.name && $0.challengeId == medal.challengeId }) {
                    userMedals.append(medal)
                }
            }

            user.medals = userMedals

            try userRef.setData(from: user)
        } catch {
            print("❌ addMedals > Erreur: \(error)")
        }
    }

    func persistProgress(_ progress: ParticipantProgress) async {
        do {
            try db.collection("challenges")
                .document(progress.challengeId)
                .collection("participants")
                .document(progress.id)
                .setData(from: progress)
            print("✅ Progress sauvegardé pour \(progress.id) dans défi \(progress.challengeId)")
        } catch {
            print("❌ Erreur Firestore persistProgress: \(error)")
        }
    }
}
