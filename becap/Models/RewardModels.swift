import Foundation

enum RewardCategory: String, Codable {
    case medal
    case joker
    case boost
    case cosmetic
    case ticket
    case theme
    case skin
    case visibilityBoost
    case superLike
    case xp
    case sticker
    case seasonUnlock
}

struct RewardGrant: Codable, Identifiable, Hashable {
    let id: String
    let category: RewardCategory
    let name: String
    let description: String
    let quantity: Int
    let expiresAt: Date?
    let metadata: [String: String]?

    init(
        id: String = UUID().uuidString,
        category: RewardCategory,
        name: String,
        description: String,
        quantity: Int = 1,
        expiresAt: Date? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.description = description
        self.quantity = quantity
        self.expiresAt = expiresAt
        self.metadata = metadata
    }
}

struct RewardProbabilityBucket: Codable {
    let minimumStreak: Int
    let rewards: [RewardGrant]
}

struct WeeklyWheelSegment: Codable {
    let weight: Int
    let reward: RewardGrant
}

enum XPSource: String, Codable {
    case photoPost
    case comment
    case challengeCompletion
    case invite
    case streakMaintenance
}

struct XPRewardRule: Codable {
    let source: XPSource
    let points: Int
}

struct SeasonRewardTier: Codable, Identifiable {
    let id: String
    let requiredPoints: Int
    let reward: RewardGrant
    let seasonalOnly: Bool

    init(id: String = UUID().uuidString, requiredPoints: Int, reward: RewardGrant, seasonalOnly: Bool = true) {
        self.id = id
        self.requiredPoints = requiredPoints
        self.reward = reward
        self.seasonalOnly = seasonalOnly
    }
}
