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

    private let dailyChestBuckets: [RewardProbabilityBucket] = [
        RewardProbabilityBucket(
            minimumStreak: 1,
            rewards: [
                RewardGrant(
                    category: .joker,
                    name: "Joker quotidien",
                    description: "Un joker pour sauver ta série.",
                    quantity: 1
                ),
                RewardGrant(
                    category: .cosmetic,
                    name: "Sticker bronze",
                    description: "Un sticker pour décorer ton profil."
                ),
                RewardGrant(
                    category: .ticket,
                    name: "Ticket chance",
                    description: "Ticket pour la roue hebdomadaire bonus."
                )
            ]
        ),
        RewardProbabilityBucket(
            minimumStreak: 7,
            rewards: [
                RewardGrant(
                    category: .boost,
                    name: "Boost de likes",
                    description: "Double les likes reçus pendant 1h.",
                    quantity: 1,
                    expiresAt: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
                ),
                RewardGrant(
                    category: .cosmetic,
                    name: "Thème coloré",
                    description: "Débloque un thème premium pour l'UI.",
                    metadata: ["theme": "sunrise"]
                ),
                RewardGrant(
                    category: .ticket,
                    name: "Ticket chance +",
                    description: "Ajout d'une chance supplémentaire sur la roue hebdomadaire."
                )
            ]
        ),
        RewardProbabilityBucket(
            minimumStreak: 21,
            rewards: [
                RewardGrant(
                    category: .superLike,
                    name: "Super like",
                    description: "Compte pour 3 likes sur une photo de défi.",
                    quantity: 1
                ),
                RewardGrant(
                    category: .skin,
                    name: "Skin calendrier épique",
                    description: "Style visuel rare pour le calendrier.",
                    metadata: ["skin": "holo"]
                ),
                RewardGrant(
                    category: .joker,
                    name: "Joker légendaire",
                    description: "Réactive un jour manqué même sur une très longue série.",
                    quantity: 1
                )
            ]
        )
    ]

    private let weeklyWheelSegments: [WeeklyWheelSegment] = [
        WeeklyWheelSegment(
            weight: 40,
            reward: RewardGrant(
                category: .joker,
                name: "Joker",
                description: "Un joker utilisable immédiatement."
            )
        ),
        WeeklyWheelSegment(
            weight: 20,
            reward: RewardGrant(
                category: .theme,
                name: "Palette premium",
                description: "Débloque une palette de couleurs rare.",
                metadata: ["theme": "neon"]
            )
        ),
        WeeklyWheelSegment(
            weight: 15,
            reward: RewardGrant(
                category: .visibilityBoost,
                name: "Boost de visibilité",
                description: "Ta photo est mise en avant dans le challenge pendant 1h.",
                expiresAt: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
            )
        ),
        WeeklyWheelSegment(
            weight: 15,
            reward: RewardGrant(
                category: .superLike,
                name: "Super like",
                description: "Compte pour 3 likes.",
                quantity: 1
            )
        ),
        WeeklyWheelSegment(
            weight: 10,
            reward: RewardGrant(
                category: .skin,
                name: "Skin calendrier",
                description: "Un skin exclusif pour le calendrier.",
                metadata: ["skin": "retro"]
            )
        )
    ]

    private let xpRules: [XPRewardRule] = [
        XPRewardRule(source: .photoPost, points: 10),
        XPRewardRule(source: .comment, points: 5),
        XPRewardRule(source: .challengeCompletion, points: 50),
        XPRewardRule(source: .invite, points: 100),
        XPRewardRule(source: .streakMaintenance, points: 20)
    ]

    private let seasonRewards: [SeasonRewardTier] = [
        SeasonRewardTier(
            requiredPoints: 50,
            reward: RewardGrant(
                category: .sticker,
                name: "Sticker saison",
                description: "Sticker exclusif de la saison."
            )
        ),
        SeasonRewardTier(
            requiredPoints: 150,
            reward: RewardGrant(
                category: .cosmetic,
                name: "Bordure épique",
                description: "Bordure animée pour tes photos."
            )
        ),
        SeasonRewardTier(
            requiredPoints: 300,
            reward: RewardGrant(
                category: .seasonUnlock,
                name: "Super joker saisonnier",
                description: "Un super joker utilisable une fois par saison.",
                quantity: 1
            )
        )
    ]

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

    // MARK: - Expanded reward logic

    func dailyChestReward(for streak: Int) -> RewardGrant {
        let bucket = bestBucket(for: streak)
        return bucket.rewards.randomElement() ?? fallbackReward()
    }

    func weeklyWheelReward() -> RewardGrant {
        let segment = weightedRandomSegment()
        return segment.reward
    }

    func xpPoints(for source: XPSource) -> Int {
        xpRules.first(where: { $0.source == source })?.points ?? 0
    }

    func unlockedSeasonRewards(for points: Int) -> [RewardGrant] {
        seasonRewards
            .sorted(by: { $0.requiredPoints < $1.requiredPoints })
            .compactMap { tier in
                points >= tier.requiredPoints ? tier.reward : nil
            }
    }

    // MARK: - Private helpers

    private func bestBucket(for streak: Int) -> RewardProbabilityBucket {
        guard var selected = dailyChestBuckets.min(by: { $0.minimumStreak < $1.minimumStreak }) else {
            return RewardProbabilityBucket(minimumStreak: 0, rewards: [fallbackReward()])
        }

        for bucket in dailyChestBuckets.sorted(by: { $0.minimumStreak < $1.minimumStreak }) where streak >= bucket.minimumStreak {
            selected = bucket
        }

        return selected
    }

    private func weightedRandomSegment() -> WeeklyWheelSegment {
        guard let firstSegment = weeklyWheelSegments.first else {
            return WeeklyWheelSegment(weight: 1, reward: fallbackReward())
        }

        let totalWeight = weeklyWheelSegments.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return firstSegment }

        let randomValue = Int.random(in: 1...totalWeight)
        var cumulative = 0

        for segment in weeklyWheelSegments {
            cumulative += segment.weight
            if randomValue <= cumulative {
                return segment
            }
        }

        return firstSegment
    }

    private func fallbackReward() -> RewardGrant {
        RewardGrant(
            category: .sticker,
            name: "Sticker de participation",
            description: "Merci de revenir chaque jour !"
        )
    }
}
