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

struct Challenge: Identifiable, Codable, Hashable {
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

    var likes: [String]?
    var jokerState: PostJokerState?

    var media: ChallengeMedia

    init(challengeId: String,
         authorUid: String,
         authorName: String,
         description: String?,
         date: Date,
         likes: [String]? = nil,
         jokerState: PostJokerState? = nil,
         media: ChallengeMedia) {
        self.challengeId = challengeId
        self.authorUid = authorUid
        self.authorName = authorName
        self.description = description
        self.date = date
        self.likes = likes
        self.jokerState = jokerState
        self.media = media
    }

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

struct PostDeepLink: Equatable {
    let challengeId: String
    let postId: String
}

import SwiftUI

final class DeepLinkRouter: ObservableObject {
    @Published var pendingCalendarChallengeId: String? = nil
    @Published var pendingPostLink: PostDeepLink? = nil

    private let notificationCenter: NotificationCenter
    private var notificationObserver: NSObjectProtocol?

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        notificationObserver = notificationCenter.addObserver(forName: .deepLinkRouterHandleExternalURL,
                                                              object: nil,
                                                              queue: .main) { [weak self] notification in
            guard let url = notification.userInfo?["url"] as? URL else { return }
            self?.handle(url: url)
        }
    }

    deinit {
        if let observer = notificationObserver {
            notificationCenter.removeObserver(observer)
        }
    }

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
            let postId = comps.queryItems?.first(where: { $0.name == "photoId" })?.value

            guard let challengeId, !challengeId.isEmpty,
                  let postId, !postId.isEmpty else { return }

            DispatchQueue.main.async {
                // Définir d'abord la cible photo pour que les observateurs disposent
                // de l'identifiant avant que le challenge ne déclenche la navigation.
                self.pendingPostLink = PostDeepLink(challengeId: challengeId, postId: postId)
                self.pendingCalendarChallengeId = challengeId
            }

        default:
            break
        }
    }

    func clearChallengeNavigation() {
        pendingCalendarChallengeId = nil
    }

    func clearPostNavigation() {
        pendingPostLink = nil
    }
}

extension Notification.Name {
    static let deepLinkRouterHandleExternalURL = Notification.Name("DeepLinkRouter.HandleExternalURL")
}
