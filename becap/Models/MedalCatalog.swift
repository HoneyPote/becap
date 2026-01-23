//
//  MedalCatalog.swift
//  becap
//
//  Created by OpenAI on 12/02/2026.
//

import Foundation

enum MedalCategory: String, CaseIterable {
    case streak = "Série"
    case consistency = "Régularité"
    case social = "Communauté"
    case joker = "Jokers"
    case creation = "Création"
    case milestone = "Étapes"
}

enum MedalTier: String {
    case bronze
    case silver
    case gold
    case platinum
}

enum SocialMedalType: String {
    case firstPost
    case firstComment
    case firstLike
    case firstReaction
}

struct MedalDefinition: Identifiable, Hashable {
    let name: String
    let description: String
    let iconName: String
    let category: MedalCategory
    let tier: MedalTier
    let streakDays: Int?
    let isCompletion: Bool

    var id: String { name }
}

enum MedalCatalog {
    private static func streakMedalDefinition(for days: Int) -> MedalDefinition {
        switch days {
        case 1:
            return MedalDefinition(name: "🚀 Premier jour",
                                   description: "Première validation !",
                                   iconName: "rocket.fill",
                                   category: .streak,
                                   tier: .bronze,
                                   streakDays: 1,
                                   isCompletion: false)
        case 2:
            return MedalDefinition(name: "⚡ 2 jours",
                                   description: "Déjà 2 jours d'affilée",
                                   iconName: "bolt.fill",
                                   category: .streak,
                                   tier: .bronze,
                                   streakDays: 2,
                                   isCompletion: false)
        case 3:
            return MedalDefinition(name: "🔥 3 jours",
                                   description: "3 jours validés d'affilée",
                                   iconName: "flame.fill",
                                   category: .streak,
                                   tier: .bronze,
                                   streakDays: 3,
                                   isCompletion: false)
        case 4:
            return MedalDefinition(name: "💫 4 jours",
                                   description: "4 jours sans casser la série",
                                   iconName: "sparkles",
                                   category: .streak,
                                   tier: .bronze,
                                   streakDays: 4,
                                   isCompletion: false)
        case 5:
            return MedalDefinition(name: "🥉 5 jours",
                                   description: "5 jours validés d'affilée",
                                   iconName: "rosette",
                                   category: .streak,
                                   tier: .silver,
                                   streakDays: 5,
                                   isCompletion: false)
        case 6:
            return MedalDefinition(name: "🌟 6 jours",
                                   description: "6 jours de suite, bravo !",
                                   iconName: "star.fill",
                                   category: .streak,
                                   tier: .silver,
                                   streakDays: 6,
                                   isCompletion: false)
        case 7:
            return MedalDefinition(name: "🎖️ 7 jours",
                                   description: "7 jours validés d'affilée",
                                   iconName: "seal.fill",
                                   category: .streak,
                                   tier: .silver,
                                   streakDays: 7,
                                   isCompletion: false)
        case 10:
            return MedalDefinition(name: "🧨 10 jours",
                                   description: "10 jours validés d'affilée",
                                   iconName: "sun.max.fill",
                                   category: .streak,
                                   tier: .silver,
                                   streakDays: 10,
                                   isCompletion: false)
        case 14:
            return MedalDefinition(name: "🥈 14 jours",
                                   description: "14 jours de suite !",
                                   iconName: "crown.fill",
                                   category: .streak,
                                   tier: .gold,
                                   streakDays: 14,
                                   isCompletion: false)
        case 21:
            return MedalDefinition(name: "🥇21 jours",
                                   description: "21 jours de suite !",
                                   iconName: "crown",
                                   category: .streak,
                                   tier: .gold,
                                   streakDays: 21,
                                   isCompletion: false)
        case 25:
            return MedalDefinition(name: "25 jours",
                                   description: "25 jours de suite !",
                                   iconName: "trophy.fill",
                                   category: .streak,
                                   tier: .platinum,
                                   streakDays: 25,
                                   isCompletion: false)
        default:
            return MedalDefinition(name: "\(days) jours",
                                   description: "\(days) jours de suite",
                                   iconName: "star",
                                   category: .streak,
                                   tier: .bronze,
                                   streakDays: days,
                                   isCompletion: false)
        }
    }

    static func streakDefinitions(maxDays: Int) -> [MedalDefinition] {
        let baseThresholds = [1, 2, 3, 4, 5, 6, 7, 10, 14, 21, 25]
        let thresholds = baseThresholds.filter { $0 <= maxDays }
        return thresholds.map { streakMedalDefinition(for: $0) }
    }

    static func streakDefinitions(for challenge: Challenge) -> [MedalDefinition] {
        streakDefinitions(maxDays: challenge.duration)
    }

    static var completionDefinition: MedalDefinition {
        MedalDefinition(name: "🏁 🥇Terminé",
                        description: "Défi complété",
                        iconName: "flag.checkered",
                        category: .milestone,
                        tier: .platinum,
                        streakDays: nil,
                        isCompletion: true)
    }

    static var consistencyDefinitions: [MedalDefinition] {
        [
            MedalDefinition(name: "📅 Semaine solide",
                            description: "5 validations sur les 7 derniers jours",
                            iconName: "calendar.badge.checkmark",
                            category: .consistency,
                            tier: .silver,
                            streakDays: nil,
                            isCompletion: false),
            MedalDefinition(name: "💪 Reprise",
                            description: "Tu as relancé ta série après une pause",
                            iconName: "arrow.counterclockwise",
                            category: .consistency,
                            tier: .bronze,
                            streakDays: nil,
                            isCompletion: false)
        ]
    }

    static var socialDefinitions: [MedalDefinition] {
        [
            MedalDefinition(name: "📸 Premier post",
                            description: "Ton premier post dans un défi",
                            iconName: "camera.fill",
                            category: .social,
                            tier: .bronze,
                            streakDays: nil,
                            isCompletion: false),
            MedalDefinition(name: "💬 Premier commentaire",
                            description: "Premier commentaire envoyé",
                            iconName: "text.bubble.fill",
                            category: .social,
                            tier: .bronze,
                            streakDays: nil,
                            isCompletion: false),
            MedalDefinition(name: "👍 Premier like",
                            description: "Premier like donné",
                            iconName: "hand.thumbsup.fill",
                            category: .social,
                            tier: .bronze,
                            streakDays: nil,
                            isCompletion: false),
            MedalDefinition(name: "🎉 Première réaction",
                            description: "Première réaction dans le chat",
                            iconName: "sparkles",
                            category: .social,
                            tier: .bronze,
                            streakDays: nil,
                            isCompletion: false)
        ]
    }

    static var jokerDefinitions: [MedalDefinition] {
        [
            MedalDefinition(name: "🃏 Premier joker",
                            description: "Premier joker utilisé",
                            iconName: "theatermasks",
                            category: .joker,
                            tier: .bronze,
                            streakDays: nil,
                            isCompletion: false)
        ]
    }

    static var creationDefinitions: [MedalDefinition] {
        [
            MedalDefinition(name: "🛠 Premier défi",
                            description: "Tu as créé ton premier défi !",
                            iconName: "hammer",
                            category: .creation,
                            tier: .bronze,
                            streakDays: nil,
                            isCompletion: false),
            MedalDefinition(name: "👷‍♂️ Builder",
                            description: "3 défis créés",
                            iconName: "person.3.fill",
                            category: .creation,
                            tier: .silver,
                            streakDays: nil,
                            isCompletion: false)
        ]
    }

    static func definition(named name: String) -> MedalDefinition? {
        let defaultDefinitions = streakDefinitions(maxDays: 30)
            + [completionDefinition]
            + consistencyDefinitions
            + socialDefinitions
            + jokerDefinitions
            + creationDefinitions
        return defaultDefinitions.first { $0.name == name }
    }

    static func nextStreakDefinition(for progress: ParticipantProgress, challenge: Challenge) -> MedalDefinition? {
        let definitions = streakDefinitions(for: challenge)
            .sorted { ($0.streakDays ?? 0) < ($1.streakDays ?? 0) }
        return definitions.first { ($0.streakDays ?? 0) > progress.currentStreak }
    }
}
