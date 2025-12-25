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
    var dishDescription: String?
    var imageURL: String?
    var prompt: String
    var createdAt: Date
    var status: Status
    var responseJSON: String?
    var score: Double?
    var scoredAt: Date?
    var comment: String?
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
         dishDescription: String? = nil,
         imageURL: String? = nil,
         prompt: String,
         createdAt: Date = Date(),
         status: Status = .pending,
         responseJSON: String? = nil,
         score: Double? = nil,
         scoredAt: Date? = nil,
         comment: String? = nil,
         lastError: String? = nil) {
        self.id = id
        self.participantId = participantId
        self.challengeId = challengeId
        self.postId = postId
        self.dishDescription = dishDescription
        self.imageURL = imageURL
        self.prompt = prompt
        self.createdAt = createdAt
        self.status = status
        self.responseJSON = responseJSON
        self.score = score
        self.scoredAt = scoredAt
        self.comment = comment
        self.lastError = lastError
    }
}

struct ScoreResult: Codable {
    var rawJSON: String
    var score: Double?
    var comment: String?
    var model: String?
    var finishReason: String?
}

struct ScoreCard: Codable {
    let score: Double
    let comment: String?
}
