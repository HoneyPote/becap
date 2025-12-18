//
//  ChallengeEntry.swift
//  becap
//
//  Created by OpenAI's assistant on 2024-05-08.
//

import Foundation

struct ChallengeEntry: Identifiable, Codable {
    let id: UUID
    let participant: String
    let timestamp: Date
    let nomPlat: String
    let ingredients: [String]
    let notePersonnelle: String?
    let urlPhoto: URL
    let sourceMeta: [String: String]
}

struct ChallengeSourcePayload {
    let participant: String?
    let timestamp: Date?
    let nomPlat: String?
    let ingredients: [String]?
    let notePersonnelle: String?
    let urlPhoto: URL?
    let sourceMeta: [String: String]
}

struct ChallengeIngestionResult {
    let entry: ChallengeEntry?
    let error: Error?
}
