//
//  ScoreEntry.swift
//  becap
//
//  Created by OpenAI on 14/11/2025.
//

import Foundation
import FirebaseFirestore


struct ScoreEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var participantId: String
    var challengeId: String
    var postId: String?
    var prompt: String
    var createdAt: Date
    var status: Status
    var responseJSON: String?
    var score: Double?
    var scoredAt: Date?
    var lastError: String?

    enum Status: String, Codable {
        case pending
        case processing
        case completed
        case failed
    }

    init(id: String? = nil,
         participantId: String,
         challengeId: String,
         postId: String? = nil,
         prompt: String,
         createdAt: Date = Date(),
         status: Status = .pending,
         responseJSON: String? = nil,
         score: Double? = nil,
         scoredAt: Date? = nil,
         lastError: String? = nil) {
        self.id = id
        self.participantId = participantId
        self.challengeId = challengeId
        self.postId = postId
        self.prompt = prompt
        self.createdAt = createdAt
        self.status = status
        self.responseJSON = responseJSON
        self.score = score
        self.scoredAt = scoredAt
        self.lastError = lastError
    }
}

struct ScoreResult: Codable {
    var rawJSON: String
    var score: Double?
    var model: String?
    var finishReason: String?
}
