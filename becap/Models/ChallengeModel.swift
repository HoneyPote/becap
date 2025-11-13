//
//  ChallengeModel.swift
//  becap
//
//  Created by Victor Derveaux on 23/07/2025.
//

import Foundation
import FirebaseFirestore

enum ChallengeCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case sport
    case dessin
    case nourriture
    case course
    case lecture
    case autre

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sport: return "Sport"
        case .dessin: return "Dessin"
        case .nourriture: return "Nourriture"
        case .course: return "Course à pied"
        case .lecture: return "Lecture"
        case .autre: return "Autre"
        }
    }

    var calendarBackgroundImageName: String {
        switch self {
        case .sport:
            return "iphone_wallpaper_pullup"
        case .dessin:
            return "iphone_wallpaper_painter"
        case .nourriture:
            return "iphone_wallpaper_chef_clean_bright"
        case .course:
            return "iphone_wallpaper_duo_run"
        case .lecture:
            return "iphone_wallpaper_reader"
        case .autre:
            return "iphone_wallpaper_bridge"
        }
    }
}

enum ChallengeStatus: String {
    case active = "En cours"
    case finished = "Termniné"
}

struct Challenge: Identifiable, Codable, Hashable {
    @DocumentID private var _id: String?
    var id: String {
        _id ?? ""
    }
    var title: String
    var duration: Int
    var startDate: Date
    var creatorUID: String
    var participantUids: [String]
    var category: ChallengeCategory? = nil
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

extension Challenge {
    private var calendar: Calendar { Calendar.current }

    var lastDayDate: Date {
        calendar.date(byAdding: .day,
                       value: max(duration - 1, 0),
                       to: startDate) ?? startDate
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
}

struct ChallengePost: Identifiable, Codable, Hashable {
    @DocumentID private var _id: String?
    var id: String {
        _id ?? ""
    }
    var challengeId: String              // ID du défi (parent)
    var authorUid: String                // UID Firebase de l'auteur
    var authorName: String               // Nom ou prénom affiché
    var description: String?             // Description optionnelle (légende)
    var date: Date                       // Date de prise ou de soumission

    var likes: [String]? // <--- AJOUTE CE CHAMP ! (optional pour backward compatibilité)
    var jokerState: PhotoJokerState?

    var media: ChallengeMedia

    static func == (lhs: ChallengePost, rhs: ChallengePost) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum ChallengeRawMedia: Equatable {
    case image(UIImage)
    case video(VideoRawData)

    struct VideoRawData: Equatable {
        var url: URL
        var thumbnailImage: UIImage?
    }
}

enum ChallengeMedia: Codable, Hashable {
    case image(url: String)
    case video(VideoData)

    struct VideoData: Codable, Hashable {
        var videoURL: String
        var thumbnailURL: String?
    }

    enum CodingKeys: String, CodingKey {
        case type
        case imageURL
        case video
    }

    enum MediaType: String, Codable {
        case image
        case video
    }

    // MARK: - Codable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MediaType.self, forKey: .type)

        switch type {
        case .image:
            let imageURL = try container.decode(String.self, forKey: .imageURL)
            self = .image(url: imageURL)
        case .video:
            let videoData = try container.decode(VideoData.self, forKey: .video)
            self = .video(videoData)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .image(let url):
            try container.encode(MediaType.image, forKey: .type)
            try container.encode(url, forKey: .imageURL)
        case .video(let videoData):
            try container.encode(MediaType.video, forKey: .type)
            try container.encode(videoData, forKey: .video)
        }
    }

    // MARK: - Helpers

    var thumbnailImageUrl: String? {
        switch self {
        case .image(let url):
            return url
        case .video(let data):
            return data.thumbnailURL
        }
    }
}

struct ChallengeNotification: Codable {
    var dayIndex: Int
    var times: [Date] // Format "HH:mm" ou utiliser Date si tu préfères
}



struct PhotoDeepLink: Equatable {
    let challengeId: String
    let photoId: String
}

import SwiftUI

final class DeepLinkRouter: ObservableObject {
    @Published var pendingCalendarChallengeId: String? = nil
    @Published var pendingPhotoLink: PhotoDeepLink? = nil

    // Appelle ceci depuis .onOpenURL
    func handle(url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              comps.scheme?.lowercased() == "becap" else { return }

        let host = comps.host?.lowercased()

        switch host {
        case "challenge", "join":
            let challengeId = comps.queryItems?.first(where: { $0.name == "challengeId" })?.value
            DispatchQueue.main.async {
                if let challengeId, !challengeId.isEmpty {
                    self.pendingCalendarChallengeId = challengeId
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
            }

        default:
            break
        }
    }

    func clearChallengeNavigation() {
        pendingCalendarChallengeId = nil
    }

    func clearPhotoNavigation() {
        pendingPhotoLink = nil
    }
}
