//
//  AppNotification.swift
//  becap
//
//  Created by ChatGPT on 2025-XX-XX.
//

import Foundation
import FirebaseFirestore

enum AppNotificationKind: String, Codable {
    case photoPosted = "photo_posted"
    case like = "like"
    case comment = "comment"
    case reminder = "reminder"
}

struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    var type: AppNotificationKind
    var title: String
    var message: String
    var challengeId: String?
    var challengeTitle: String?
    var photoId: String?
    var commentId: String?
    var actorName: String?
    var createdAt: Date
    var isRead: Bool

    var route: NotificationRoute? {
        switch type {
        case .photoPosted, .like:
            guard let challengeId, let photoId else { return nil }
            return .photo(challengeId: challengeId, photoId: photoId, commentId: nil)
        case .comment:
            guard let challengeId, let photoId else { return nil }
            return .photo(challengeId: challengeId, photoId: photoId, commentId: commentId)
        case .reminder:
            guard let challengeId else { return nil }
            return .challenge(challengeId: challengeId)
        }
    }
}

struct NotificationSection: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let items: [NotificationItemViewModel]
}

struct NotificationItemViewModel: Identifiable, Equatable {
    let id: String
    let title: String
    let message: String
    let time: String
    let accentColor: String
    let iconName: String
    let isRead: Bool
    let route: NotificationRoute?
}
