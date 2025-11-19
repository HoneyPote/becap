//
//  PostJokerState.swift
//  becap
//
//  Created by OpenAI on 09/08/2025.
//

import Foundation

struct PostJokerState: Codable, Hashable {
    var declaredByAuthor: Bool
    var voters: [String]
    var isConfirmed: Bool
    var confirmedAt: Date?

    init(declaredByAuthor: Bool = false,
         voters: [String] = [],
         isConfirmed: Bool = false,
         confirmedAt: Date? = nil) {
        self.declaredByAuthor = declaredByAuthor
        self.voters = voters
        self.isConfirmed = isConfirmed
        self.confirmedAt = confirmedAt
    }
}
