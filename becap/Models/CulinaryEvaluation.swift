//
//  CulinaryEvaluation.swift
//  becap
//
//  Created by OpenAI on 15/05/2024.
//

import Foundation

struct CulinaryEvaluation: Codable, Identifiable {
    let id: UUID
    let dishDescription: String
    let guidanceApplied: String
    let generalFeedback: String
    let tasteScore: Int
    let presentationScore: Int
    let originalityScore: Int
    let overallCommentary: String
    let createdAt: Date

    init(id: UUID = UUID(),
         dishDescription: String,
         guidanceApplied: String,
         generalFeedback: String,
         tasteScore: Int,
         presentationScore: Int,
         originalityScore: Int,
         overallCommentary: String,
         createdAt: Date = Date()) {
        self.id = id
        self.dishDescription = dishDescription
        self.guidanceApplied = guidanceApplied
        self.generalFeedback = generalFeedback
        self.tasteScore = tasteScore
        self.presentationScore = presentationScore
        self.originalityScore = originalityScore
        self.overallCommentary = overallCommentary
        self.createdAt = createdAt
    }

    var averageScore: Double {
        let total = Double(tasteScore + presentationScore + originalityScore)
        return total / 3.0
    }
}

struct ScoreAuditEntry: Codable, Identifiable {
    let id: UUID
    let evaluation: CulinaryEvaluation
    let guardrailPrompt: String
    let rawModelResponse: String
    let detectedInconsistencies: [String]
    let createdAt: Date

    init(id: UUID = UUID(),
         evaluation: CulinaryEvaluation,
         guardrailPrompt: String,
         rawModelResponse: String,
         detectedInconsistencies: [String],
         createdAt: Date = Date()) {
        self.id = id
        self.evaluation = evaluation
        self.guardrailPrompt = guardrailPrompt
        self.rawModelResponse = rawModelResponse
        self.detectedInconsistencies = detectedInconsistencies
        self.createdAt = createdAt
    }
}
