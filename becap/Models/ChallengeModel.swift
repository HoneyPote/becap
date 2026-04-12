//
//  ChallengeModel.swift
//  becap
//
//  Created by Victor Derveaux on 23/07/2025.
//

import FirebaseFirestore

// MARK: - Challenge representable protocol
protocol ChallengeRepresentable: Identifiable, Hashable {
    var id: String { get }
    var title: String { get }
    var duration: Int { get }
    var startDate: Date { get }
    var category: ChallengeCategory? { get }
    var defaultNotificationsConfig: [Int] { get }
    var creatorUID: String { get }
    var adminUids: [String] { get }
    var participantUids: [String] { get }
    var code: String? { get }
    var jokerConfiguration: Int { get }
}

extension ChallengeRepresentable {
    private var calendar: Calendar { Calendar.current }

    var lastDayDate: Date {
        calendar.date(byAdding: .day, value: max(duration - 1, 0), to: startDate) ?? startDate
    }

    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: duration, to: startDate) ?? startDate
    }

    func isLastDay(on date: Date = Date()) -> Bool {
        calendar.isDate(lastDayDate, inSameDayAs: date)
    }

    var isLastDayToday: Bool { isLastDay() }

    var calendarBackgroundImageName: String {
        if isLastDayToday {
            return "sunset"
        }

        return category?.calendarBackgroundImageName ?? "photoBg"
    }

    var status: ChallengeStatus {
        Date() > endDate ? .finished : .active
    }
}

// MARK: - Base challenge
struct Challenge: ChallengeRepresentable, Identifiable, Codable, Hashable {
    @DocumentID private var _id: String?
    var id: String {
        _id ?? ""
    }
    var title: String
    var duration: Int
    var startDate: Date
    var creatorUID: String
    var adminUids: [String]
    var participantUids: [String]
    var category: ChallengeCategory? = nil
    var defaultNotificationsConfig: [Int]
    var code: String?
    var jokerConfiguration: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
    }

    static func == (lhs: Challenge, rhs: Challenge) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}

enum ChallengeCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case sport
    case drawing
    case food
    case running
    case reading
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sport: return "Sport"
        case .drawing: return "Dessin"
        case .food: return "Nourriture"
        case .running: return "Course à pied"
        case .reading: return "Lecture"
        case .other: return "Autre"
        }
    }

    var calendarBackgroundImageName: String {
        switch self {
        case .sport:
            return "iphone_wallpaper_pullup"
        case .drawing:
            return "iphone_wallpaper_painter"
        case .food:
            return "iphone_wallpaper_chef_clean_bright"
        case .running:
            return "iphone_wallpaper_duo_run"
        case .reading:
            return "iphone_wallpaper_reader"
        case .other:
            return "iphone_wallpaper_bridge"
        }
    }
}

enum ChallengeStatus: String {
    case active = "En cours"
    case finished = "Terminé"
}


// MARK: - Becap challenges
struct BecapChallenge: ChallengeRepresentable {
    let base: Challenge
    let becapData: BecapChallengeData

    var id: String { base.id }
    var title: String { base.title }
    var duration: Int { base.duration }
    var startDate: Date { base.startDate }
    var category: ChallengeCategory? { base.category }
    var defaultNotificationsConfig: [Int] { base.defaultNotificationsConfig }
    var creatorUID: String { base.creatorUID }
    var adminUids: [String] { base.adminUids }
    var participantUids: [String] { base.participantUids }
    var code: String? { base.code }
    var jokerConfiguration: Int { base.jokerConfiguration }

    var type: BecapChallengeType { becapData.type }
    var configuration: BecapChallengeConfiguration { becapData.configuration }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
    }

    static func == (lhs: BecapChallenge, rhs: BecapChallenge) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}

struct BecapChallengeData: Codable {
    var challengeId: String
    var type: BecapChallengeType
    var configuration: BecapChallengeConfiguration
}

enum BecapChallengeType: String, Codable {
    case plank
    case reading
    case food
    case drawing

    var defaultConfiguration: BecapChallengeConfiguration {
        switch self {
        case .plank:
            return .plank(PlankConfig(secondsPerDay: 60))

        case .reading:
            return .reading(ReadingConfig(pagesPerDay: 10))

        case .food:
            return .food(FoodConfig(cheatMealsAllowed: 3))

        case .drawing:
            return .drawing(DrawingConfig(drawingsPerDay: 1))
        }
    }
}

enum BecapChallengeConfiguration: Hashable {
    case plank(PlankConfig)
    case reading(ReadingConfig)
    case food(FoodConfig)
    case drawing(DrawingConfig)

    enum CodingKeys: String, CodingKey {
        case type
        case config
    }

    enum ConfigType: String, Codable {
        case plank
        case reading
        case food
        case drawing
    }

    var displayName: String {
        switch self {
        case .plank: return "Gainage"
        case .reading: return "Lecture"
        case .food: return "Nourriture"
        case .drawing: return "Dessin"
        }
    }

    var primaryValue: Int {
        switch self {
        case .plank(let config):
            return config.secondsPerDay
        case .reading(let config):
            return config.pagesPerDay
        case .food(let config):
            return config.cheatMealsAllowed
        case .drawing(let config):
            return config.drawingsPerDay
        }
    }
}

extension BecapChallengeConfiguration: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ConfigType.self, forKey: .type)

        switch type {
        case .plank:
            let config = try container.decode(PlankConfig.self, forKey: .config)
            self = .plank(config)

        case .reading:
            let config = try container.decode(ReadingConfig.self, forKey: .config)
            self = .reading(config)

        case .food:
            let config = try container.decode(FoodConfig.self, forKey: .config)
            self = .food(config)

        case .drawing:
            let config = try container.decode(DrawingConfig.self, forKey: .config)
            self = .drawing(config)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .plank(let config):
            try container.encode(ConfigType.plank, forKey: .type)
            try container.encode(config, forKey: .config)

        case .reading(let config):
            try container.encode(ConfigType.reading, forKey: .type)
            try container.encode(config, forKey: .config)

        case .food(let config):
            try container.encode(ConfigType.food, forKey: .type)
            try container.encode(config, forKey: .config)

        case .drawing(let config):
            try container.encode(ConfigType.drawing, forKey: .type)
            try container.encode(config, forKey: .config)
        }
    }
}

struct PlankConfig: Codable, Hashable {
    var secondsPerDay: Int
}

struct ReadingConfig: Codable, Hashable {
    var pagesPerDay: Int
}

struct FoodConfig: Codable, Hashable {
    var cheatMealsAllowed: Int
}

struct DrawingConfig: Codable, Hashable {
    var drawingsPerDay: Int
}
