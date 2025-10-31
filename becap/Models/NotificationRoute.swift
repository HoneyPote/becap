//
//  NotificationRoute.swift
//  becap
//
//  Created by ChatGPT on 2025-XX-XX.
//

import Foundation

enum NotificationRoute: Equatable {
    case challenge(challengeId: String)
    case photo(challengeId: String, photoId: String, commentId: String?)
}

extension Notification.Name {
    static let didReceiveNotificationRoute = Notification.Name("becap.didReceiveNotificationRoute")
}
