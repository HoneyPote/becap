//
//  Defi.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

// ChallengeApp/Models/Defi.swift

import Foundation

struct Defi: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var startDate: Date
    var duration: Int
    var participants: [String]
    var notificationConfig: [DefiNotificationDayConfig]
}

struct DefiNotificationDayConfig: Codable, Hashable {
    var dayIndex: Int        // 0 = first day, 1 = second, ...
    var times: [Date]        // Notification times for that day
}

struct PhotoDefi: Identifiable, Codable, Hashable {
    var id = UUID()
    var defiId: UUID
    var date: Date
    var prenomAuteur: String
    var imagePath: String
    var description: String? // <- Optionnel
}
