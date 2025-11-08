//
//  JokerUsage.swift
//  becap
//
//  Created by OpenAI on 09/08/2025.
//

import Foundation

struct JokerUsage: Identifiable, Codable, Hashable {
    var id: String
    var date: Date
    var photoId: String?
    var declaredByAuthor: Bool
    var voters: [String]
    var status: JokerUsageStatus
    var confirmedAt: Date?

    init(id: String = UUID().uuidString,
         date: Date,
         photoId: String? = nil,
         declaredByAuthor: Bool,
         voters: [String] = [],
         status: JokerUsageStatus,
         confirmedAt: Date? = nil) {
        self.id = id
        self.date = date
        self.photoId = photoId
        self.declaredByAuthor = declaredByAuthor
        self.voters = voters
        self.status = status
        self.confirmedAt = confirmedAt
    }
}
