//
//  ScoreAggregation.swift
//  becap
//
//  Created by OpenAI on 14/11/2025.
//

import Foundation
import FirebaseFirestore

struct ScoreAggregation: Identifiable, Codable {
    @DocumentID var id: String?
    var participantId: String
    var challengeId: String
    var granularity: Granularity
    var periodStart: Date?
    var averageScore: Double
    var totalScore: Double
    var count: Int

    enum Granularity: String, Codable {
        case day
        case week
        case month
        case overall
    }
}
