//
//  ScoringService.swift
//  becap
//
//  Created by OpenAI on 14/11/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

protocol ScoringServiceProtocol {
    func fetchUnscoredEntries(limit: Int) async throws -> [ScoreEntry]
    func processPendingEntries(limit: Int) async
    func computeAggregations(for participantId: String, challengeId: String) async throws
    func enqueueScoreEntry(for post: ChallengePost, in challenge: Challenge) async throws
    func fetchScores(for challengeId: String, postIds: [String]) async throws -> [String: Double]
    func fetchAggregations(for challengeId: String,
                          granularity: ScoreAggregation.Granularity) async throws -> [ScoreAggregation]
}

enum ScoringServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case dailyQuotaExceeded

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "La clé API OpenAI est manquante."
        case .invalidResponse:
            return "Réponse du modèle GPT invalide."
        case .dailyQuotaExceeded:
            return "Le plafond quotidien de requêtes a été atteint."
        }
    }
}

final class ScoringService: ScoringServiceProtocol {
    static let shared = ScoringService()

    private let firestore = Firestore.firestore()
    private let entriesCollection = "scoreEntries"
    private let aggregatesCollection = "scoreAggregates"
    private let usageCollection = "scoreRequestUsage"
    private let openAIURL = URL(string: "https://api.openai.com/v1/chat/completions")
    private let maxRetries = 5
    private let dailyQuota = 50
    private let calendar = Calendar.current
    private let promptDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private init() {}

    // MARK: - Public API

    func enqueueScoreEntry(for post: ChallengePost, in challenge: Challenge) async throws {
        let prompt = buildPrompt(for: post, challenge: challenge)
        let scoreEntry = ScoreEntry(
            participantId: post.authorUid,
            challengeId: challenge.id,
            postId: post.id.isEmpty ? nil : post.id,
            prompt: prompt,
            createdAt: Date(),
            status: .pending,
            responseJSON: nil,
            score: nil,
            scoredAt: nil,
            lastError: nil
        )

        _ = try firestore.collection(entriesCollection).addDocument(from: scoreEntry)
    }

    func fetchScores(for challengeId: String, postIds: [String]) async throws -> [String: Double] {
        guard !postIds.isEmpty else { return [:] }

        let snapshot = try await firestore.collection(entriesCollection)
            .whereField("challengeId", isEqualTo: challengeId)
            .whereField("status", isEqualTo: ScoreEntry.Status.completed.rawValue)
            .getDocuments()

        let entries = snapshot.documents.compactMap { try? $0.data(as: ScoreEntry.self) }

        return entries.reduce(into: [:]) { result, entry in
            guard let postId = entry.postId,
                  postIds.contains(postId),
                  let score = entry.score else { return }
            result[postId] = score
        }
    }

    func fetchAggregations(for challengeId: String,
                          granularity: ScoreAggregation.Granularity) async throws -> [ScoreAggregation] {
        let snapshot = try await firestore.collection(aggregatesCollection)
            .whereField("challengeId", isEqualTo: challengeId)
            .whereField("granularity", isEqualTo: granularity.rawValue)
            .order(by: "averageScore", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: ScoreAggregation.self) }
    }

    func fetchUnscoredEntries(limit: Int = 10) async throws -> [ScoreEntry] {
        let query = firestore.collection(entriesCollection)
            .whereField("status", isEqualTo: ScoreEntry.Status.pending.rawValue)
            .order(by: "createdAt")
            .limit(to: limit)

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: ScoreEntry.self) }
    }

    func processPendingEntries(limit: Int = 10) async {
        do {
            let entries = try await fetchUnscoredEntries(limit: limit)

            for entry in entries {
                await process(entry: entry)
            }
        } catch {
            print("[ScoringService] Échec lors de la récupération des entrées: \(error.localizedDescription)")
        }
    }

    func computeAggregations(for participantId: String, challengeId: String) async throws {
        let query = firestore.collection(entriesCollection)
            .whereField("participantId", isEqualTo: participantId)
            .whereField("challengeId", isEqualTo: challengeId)
            .whereField("status", isEqualTo: ScoreEntry.Status.completed.rawValue)

        let snapshot = try await query.getDocuments()
        let entries = snapshot.documents.compactMap { try? $0.data(as: ScoreEntry.self) }
        let scoredEntries = entries.compactMap { entry -> (Date, Double)? in
            guard let score = entry.score else { return nil }
            return (entry.scoredAt ?? entry.createdAt, score)
        }

        try await updateAggregations(scoredEntries: scoredEntries,
                                     participantId: participantId,
                                     challengeId: challengeId)
    }
}

// MARK: - Processing
private extension ScoringService {
    func buildPrompt(for post: ChallengePost, challenge: Challenge) -> String {
        let description = post.description?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        let userDescription = description?.isEmpty == false ? description! : "Aucune description fournie"

        return """
        \(CulinaryFeedbackService.shared.guardrailPrompt)

        Tu fais partie du jury du défi communautaire «\(challenge.title)» (catégorie : \(challenge.category?.displayName ?? "Non renseignée")).
        Analyse la contribution suivante et attribue une note globale sur 10 en tenant compte du nom du plat, des ingrédients cités et de l'impression générale.

        Détails du post :
        - Participant : \(post.authorName)
        - Période : \(promptDateFormatter.string(from: post.date))
        - Type de média : \(mediaDescription(from: post.media))
        - Description du plat : \(userDescription)

        Réponds uniquement avec un JSON valide et minimal de la forme :
        {"score": <nombre entre 0 et 10>, "commentaire": "<phrase courte et encourageante en français>"}
        """
    }

    func mediaDescription(from media: ChallengeMedia) -> String {
        switch media {
        case .image:
            return "Photo"
        case .video(let data):
            if let thumb = data.thumbnailURL {
                return "Vidéo (miniature: \(thumb))"
            }
            return "Vidéo"
        }
    }

    func process(entry: ScoreEntry) async {
        guard let entryId = entry.id else { return }

        do {
            try await enforceDailyQuota(for: entry.participantId)
            try await markProcessing(entryId: entryId)

            let result = try await sendPrompt(for: entry)
            try await persist(result: result, for: entry)
            try await computeAggregations(for: entry.participantId, challengeId: entry.challengeId)
        } catch {
            print("[ScoringService] Erreur pour l’entrée \(entryId): \(error.localizedDescription)")
            try? await markFailed(entryId: entryId, error: error)
        }
    }

    func markProcessing(entryId: String) async throws {
        try await firestore.collection(entriesCollection)
            .document(entryId)
            .updateData([
                "status": ScoreEntry.Status.processing.rawValue,
                "lastError": FieldValue.delete()
            ])
    }

    func markFailed(entryId: String, error: Error) async throws {
        try await firestore.collection(entriesCollection)
            .document(entryId)
            .updateData([
                "status": ScoreEntry.Status.failed.rawValue,
                "lastError": error.localizedDescription
            ])
    }

    func enforceDailyQuota(for participantId: String) async throws {
        let todayKey = formattedDay(Date())
        let usageRef = firestore.collection(usageCollection).document(participantId)
        let snapshot = try await usageRef.getDocument()
        var data = snapshot.data() ?? [:]
        let currentUsage = data[todayKey] as? Int ?? 0

        guard currentUsage < dailyQuota else {
            throw ScoringServiceError.dailyQuotaExceeded
        }

        data[todayKey] = currentUsage + 1
        try await usageRef.setData(data, merge: true)
    }
}

// MARK: - GPT Communication
private extension ScoringService {
    func sendPrompt(for entry: ScoreEntry) async throws -> ScoreResult {
        guard let apiKey = BecapSecrets.openAIAPIKey else {
            throw ScoringServiceError.missingAPIKey
        }

        guard let url = openAIURL else {
            throw URLError(.badURL)
        }

        let requestBody = ChatRequest(messages: [
            .init(role: "user", content: entry.prompt)
        ])

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(requestBody)

        let data = try await performRequestWithRetry(request: urlRequest)
        return try parseGPTResponse(data: data)
    }

    func performRequestWithRetry(request: URLRequest) async throws -> Data {
        var attempt = 0
        var currentDelay: UInt64 = 500_000_000 // 0.5s

        while attempt < maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) {
                    return data
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
                    throw URLError(.cannotLoadFromNetwork)
                } else {
                    throw ScoringServiceError.invalidResponse
                }
            } catch {
                attempt += 1
                if attempt >= maxRetries {
                    throw error
                }

                print("[ScoringService] tentative \(attempt) échouée: \(error.localizedDescription). Retry dans \(currentDelay / 1_000_000_000)s")
                try await Task.sleep(nanoseconds: currentDelay)
                currentDelay *= 2
            }
        }

        throw ScoringServiceError.invalidResponse
    }

    func parseGPTResponse(data: Data) throws -> ScoreResult {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let apiResponse = try decoder.decode(OpenAIChatResponse.self, from: data)
        guard let message = apiResponse.choices.first?.message else {
            throw ScoringServiceError.invalidResponse
        }

        let rawString = message.content
        let score = extractScore(from: message.content)

        let jsonString: String
        if let jsonData = try? JSONSerialization.data(withJSONObject: apiResponse.dictionaryRepresentation(), options: .prettyPrinted),
           let string = String(data: jsonData, encoding: .utf8) {
            jsonString = string
        } else {
            jsonString = rawString
        }

        return ScoreResult(rawJSON: jsonString,
                           score: score,
                           model: apiResponse.model,
                           finishReason: apiResponse.choices.first?.finishReason)
    }

    func extractScore(from content: String) -> Double? {
        if let data = content.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(ScoreContent.self, from: data) {
            return decoded.score
        }

        if let data = content.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let score = json["score"] as? Double {
            return score
        }

        return nil
    }
}

// MARK: - Aggregations
private extension ScoringService {
    func persist(result: ScoreResult, for entry: ScoreEntry) async throws {
        guard let entryId = entry.id else { return }

        var updates: [String: Any] = [
            "status": ScoreEntry.Status.completed.rawValue,
            "responseJSON": result.rawJSON,
            "scoredAt": FieldValue.serverTimestamp()
        ]

        if let score = result.score {
            updates["score"] = score
        }

        try await firestore.collection(entriesCollection).document(entryId).updateData(updates)
    }

    func updateAggregations(scoredEntries: [(Date, Double)],
                            participantId: String,
                            challengeId: String) async throws {
        let totalScore = scoredEntries.reduce(0.0) { $0 + $1.1 }
        let count = scoredEntries.count
        let overall = ScoreAggregation(id: nil,
                                       participantId: participantId,
                                       challengeId: challengeId,
                                       granularity: .overall,
                                       periodStart: nil,
                                       averageScore: count > 0 ? totalScore / Double(count) : 0,
                                       totalScore: totalScore,
                                       count: count)

        try await upsertAggregation(overall)

        let groupedByDay = Dictionary(grouping: scoredEntries) { calendar.startOfDay(for: $0.0) }
        try await persistAggregations(from: groupedByDay, granularity: .day, participantId: participantId, challengeId: challengeId)

        let groupedByWeek = Dictionary(grouping: scoredEntries) { calendar.dateInterval(of: .weekOfYear, for: $0.0)?.start ?? $0.0 }
        try await persistAggregations(from: groupedByWeek, granularity: .week, participantId: participantId, challengeId: challengeId)

        let groupedByMonth = Dictionary(grouping: scoredEntries) { calendar.dateInterval(of: .month, for: $0.0)?.start ?? $0.0 }
        try await persistAggregations(from: groupedByMonth, granularity: .month, participantId: participantId, challengeId: challengeId)
    }

    func persistAggregations(from groups: [Date: [(Date, Double)]],
                             granularity: ScoreAggregation.Granularity,
                             participantId: String,
                             challengeId: String) async throws {
        for (startDate, entries) in groups {
            let totalScore = entries.reduce(0.0) { $0 + $1.1 }
            let count = entries.count
            let aggregation = ScoreAggregation(id: nil,
                                               participantId: participantId,
                                               challengeId: challengeId,
                                               granularity: granularity,
                                               periodStart: startDate,
                                               averageScore: count > 0 ? totalScore / Double(count) : 0,
                                               totalScore: totalScore,
                                               count: count)
            try await upsertAggregation(aggregation)
        }
    }

    func upsertAggregation(_ aggregation: ScoreAggregation) async throws {
        let docId = buildAggregationId(for: aggregation)
        try firestore.collection(aggregatesCollection)
            .document(docId)
            .setData(try Firestore.Encoder().encode(aggregation), merge: true)
    }

    func buildAggregationId(for aggregation: ScoreAggregation) -> String {
        var components: [String] = [aggregation.participantId, aggregation.challengeId, aggregation.granularity.rawValue]
        if let period = aggregation.periodStart {
            components.append(String(Int(period.timeIntervalSince1970)))
        }
        return components.joined(separator: "_")
    }
}

// MARK: - Helpers
private extension ScoringService {
    func formattedDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - OpenAI DTOs
private struct ChatRequest: Encodable {
    var model: String = "gpt-4o-mini"
    var messages: [Message]
    var temperature: Double = 0.2

    struct Message: Encodable {
        var role: String
        var content: String
    }
}

private struct OpenAIChatResponse: Decodable {
    var id: String
    var object: String
    var created: TimeInterval
    var model: String
    var choices: [Choice]

    struct Choice: Decodable {
        var index: Int
        var message: ChoiceMessage
        var finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }

    struct ChoiceMessage: Decodable {
        var role: String
        var content: String
    }
}

private extension OpenAIChatResponse {
    func dictionaryRepresentation() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return object
    }
}

private struct ScoreContent: Decodable {
    let score: Double?
}
