//
//  NotificationPayloadParser.swift
//  becap
//
//  Created by OpenAI Assistant on 21/05/2024.
//

import Foundation

enum NotificationPayloadParser {
    static func deepLink(from userInfo: [AnyHashable: Any]) -> AppDeepLink? {
        guard let additionalData = extractAdditionalData(from: userInfo),
              let type = additionalData["type"] as? String else {
            return nil
        }

        switch type {
        case "photo-activity":
            guard let challengeId = additionalData["challengeId"] as? String,
                  let photoId = additionalData["photoId"] as? String else {
                return nil
            }
            return .calendarPhoto(challengeId: challengeId, photoId: photoId)
        default:
            return nil
        }
    }

    private static func extractAdditionalData(from userInfo: [AnyHashable: Any]) -> [String: Any]? {
        if let directData = userInfo["data"] as? [String: Any] {
            return directData
        }

        if let customDictionary = userInfo["custom"] as? [String: Any],
           let additional = customDictionary["a"] as? [String: Any] {
            return additional
        }

        if let customString = userInfo["custom"] as? String,
           let data = customString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let additional = json["a"] as? [String: Any] {
            return additional
        }

        if let osData = userInfo["os_data"] as? [String: Any],
           let custom = osData["custom"] as? [String: Any],
           let additional = custom["a"] as? [String: Any] {
            return additional
        }

        return nil
    }
}
