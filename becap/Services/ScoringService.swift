//
//  ScoringService.swift
//  becap
//
//  Created by OpenAI on 14/11/2025.
//

import Foundation
import FirebaseFirestore

protocol ScoringServiceProtocol {
    func fetchUnscoredEntries(limit: Int) async throws -> [ScoreEntry]
    func processPendingEntries(limit: Int) async
    func processEntry(entryId: String) async

    func computeAggregations(for participantId: String, challengeId: String) async throws

    /// Crée une entry de scoring et retourne son documentId
    func enqueueScoreEntry(for post: ChallengePost, in challenge: Challenge) async throws -> String

    func fetchScoreCards(for challengeId: String, postIds: [String]) async throws -> [String: ScoreCard]
    func fetchAggregations(for challengeId: String,
                           granularity: ScoreAggregation.Granularity) async throws -> [ScoreAggregation]

    func testCulinaryScore(description: String) async throws -> ScoreResult
}

enum ScoringServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case invalidScorePayload
    case dailyQuotaExceeded

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "La clé API OpenAI est manquante."
        case .invalidResponse:
            return "Réponse du modèle GPT invalide."
        case .invalidScorePayload:
            return "Le payload de scoring GPT ne respecte pas le format attendu."
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

    func enqueueScoreEntry(for post: ChallengePost, in challenge: Challenge) async throws -> String {
        let prompt = buildPrompt(for: post, challenge: challenge)
        let dishDescription = post.description?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        let rawDishDescription = (dishDescription?.isEmpty == false) ? dishDescription! : "Aucune description fournie"
        let imageURL: String?

        switch post.media {
        case .image(let url):
            imageURL = url
        case .video:
            imageURL = nil
        }

        var entry = ScoreEntry(
            participantId: post.authorUid,
            challengeId: challenge.id,
            postId: post.id,
            dishDescription: rawDishDescription,
            imageURL: imageURL,
            prompt: prompt
        )

        let ref = firestore.collection(entriesCollection).document()
        entry.id = ref.documentID

        try ref.setData(from: entry)
        print("[ScoringService] Nouvelle ScoreEntry docId=\(ref.documentID) envoyé pour scoring")
        print("[ScoringService] Description plat envoyée: \(rawDishDescription)")
        return ref.documentID
    }
    func processEntry(entryId: String) async {
        do {
            let snap = try await firestore
                .collection(entriesCollection)
                .document(entryId)
                .getDocument()

            let entry = try snap.data(as: ScoreEntry.self)

            await process(entry: entry)
            print("🧪 loaded entry participantId=\(entry.participantId) status=\(entry.status.rawValue)")
        } catch {
            print("[ScoringService] processEntry error:", error)
        }
    }
    func testCulinaryScore(description: String) async throws -> ScoreResult {
        let prompt = "Test d'évaluation culinaire : \(description)"
        let messages = buildMultimodalMessages(textPrompt: prompt, imageURL: nil)
        return try await sendMessages(messages)
    }

    func fetchScoreCards(for challengeId: String, postIds: [String]) async throws -> [String: ScoreCard] {
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

            let card = ScoreCard(score: score, comment: entry.comment)
            result[postId] = card
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
        let snapshot = try await firestore.collection(entriesCollection)
            .whereField("status", isEqualTo: ScoreEntry.Status.pending.rawValue)
            .limit(to: limit)
            .getDocuments()

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
        Défi «\(challenge.title)» (catégorie : \(challenge.category?.displayName ?? "Non renseignée")).
        Détails du post :
        - Participant : \(post.authorName)
        - Période : \(promptDateFormatter.string(from: post.date))
        - Type de média : \(mediaDescription(from: post.media))
        - Description du plat : \(userDescription)

        Tu es un jury culinaire. Pondère très fortement la présentation visuelle.
        Cohérence des ingrédients = important. Goût = infère à partir de l'image + texte (mentionne si incertain).
        Réponds STRICTEMENT avec un JSON (aucun texte autour) :
        {
          "score_global": 0-10,
          "commentaire": "string courte et utile",
          "ingredients_visibles": ["..."],
          "remarques": ["..."]
        }
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
            try await markProcessing(entryId: entryId)

            let result = try await sendPrompt(for: entry)
            try await persist(result: result, for: entry) // ✅ écrit score + status=completed
        } catch {
            try? await markFailed(entryId: entryId, challengeId: entry.challengeId, error: error)
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

    func markFailed(entryId: String, challengeId: String?, error: Error) async throws {
        try await firestore.collection(entriesCollection)
            .document(entryId)
            .updateData([
                "status": ScoreEntry.Status.failed.rawValue,
                "lastError": error.localizedDescription
            ])
        NotificationCenter.default.post(name: .scoresDidUpdate, object: challengeId)
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
    extension ScoringService {
        private func sendPrompt(for entry: ScoreEntry) async throws -> ScoreResult {
            let dishDescription = entry.dishDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
            let safeDescription = (dishDescription?.isEmpty == false) ? dishDescription! : "Aucune description fournie"
            print("[ScoringService] Envoi description plat à GPT: \(safeDescription)")

            let textPrompt = buildScoringPrompt(entry: entry, dishDescription: safeDescription)
            let messages = buildMultimodalMessages(textPrompt: textPrompt, imageURL: entry.imageURL)

            return try await sendMessages(messages)
        }


        private func buildScoringPrompt(entry: ScoreEntry, dishDescription: String) -> String {
            """
            Contexte du post :
            - Défi : \(entry.challengeId)
            - Description utilisateur : \(dishDescription)

            Analyse ce plat à partir des informations fournies.
            """
        }

        private func buildMultimodalMessages(textPrompt: String, imageURL: String?) -> [MultimodalMessage] {
            var userContent: [MultimodalMessage.ContentPart] = [.text(textPrompt)]

            if let imageURL, let url = URL(string: imageURL) {
                userContent.append(.imageURL(url.absoluteString))
            }

            let systemMessage = MultimodalMessage(role: "system", content: [.text(systemPrompt)])
            let userMessage = MultimodalMessage(role: "user", content: userContent)
            return [systemMessage, userMessage]
        }

        private var systemPrompt: String {
            """
            Tu es un évaluateur culinaire objectif et rationnel.

            Ta mission est d’évaluer un plat en t’appuyant sur :
            - en priorité les ALIMENTS visibles sur la photo,
            - puis la description fournie par l’utilisateur lorsqu’elle permet
              de confirmer ou préciser ce qui n’est pas clairement visible
              (ingrédients internes, assaisonnement, mode de cuisson).

            Règles strictes :
            - Ne base jamais l’évaluation uniquement sur la présentation visuelle.
            - Ne considère la description utilisateur que si elle est cohérente
              avec ce que suggère l’image.
            - N’invente jamais d’ingrédients ou de techniques absents du visuel
              ou incompatibles avec la photo.
            - En cas d’incertitude (photo floue, ingrédients peu identifiables),
              mentionne-le explicitement dans le commentaire.

            Critères d’évaluation (par ordre d’importance) :
            1. Qualité et cohérence des ingrédients visibles
            2. Pertinence nutritionnelle globale
            3. Technique apparente (cuisson, assemblage)
            4. Présentation visuelle (critère secondaire)

            Échelle de notation :
            - 0–3 : ingrédients pauvres, incohérents ou mal exécutés
            - 4–6 : plat correct mais basique ou déséquilibré
            - 7–8 : ingrédients pertinents, bonne cohérence, exécution solide
            - 9–10 : excellente sélection d’ingrédients et maîtrise évidente

            Réponds STRICTEMENT avec un JSON valide, sans aucun texte autour.
            Format attendu EXACT :
            {
              "score_global": 0-10,
              "commentaire": "Justification concise basée sur les ingrédients visibles et la description si pertinente"
            }
            """
        }

        private func sendMessages(_ messages: [MultimodalMessage]) async throws -> ScoreResult {
            guard let apiKey = openAIAPIKey() else {
                throw ScoringServiceError.missingAPIKey
            }

            guard let url = openAIURL else {
                throw URLError(.badURL)
            }

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            urlRequest.httpBody = try JSONEncoder().encode(ChatRequest(messages: messages))

            let data = try await performRequestWithRetry(request: urlRequest)
            return try parseGPTResponse(data: data)
        }

        private func performRequestWithRetry(request: URLRequest) async throws -> Data {
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

        private func parseGPTResponse(data: Data) throws -> ScoreResult {
            let rawResponse = String(data: data, encoding: .utf8) ?? ""
            print("[ScoringService] GPT data.count = \(data.count)")
            print("[ScoringService] GPT raw preview = \(truncatedPreview(rawResponse))")

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let apiResponse = try decoder.decode(OpenAIChatResponse.self, from: data)
            guard let message = apiResponse.choices.first?.message else {
                throw ScoringServiceError.invalidResponse
            }

            print("[ScoringService] GPT model = \(apiResponse.model), choices = \(apiResponse.choices.count), finishReason = \(apiResponse.choices.first?.finishReason ?? "nil")")
            print("[ScoringService] GPT message preview = \(truncatedPreview(message.content))")
            let payload = try extractScorePayload(from: message.content)
            let score = Double(payload.scoreGlobal)
            print("[ScoringService] GPT score extrait = \(score)")
            print("[ScoringService] GPT commentaire extrait = \(payload.commentaire)")

            let jsonString = rawResponse.isEmpty ? message.content : rawResponse

            return ScoreResult(rawJSON: jsonString,
                               score: score,
                               comment: payload.commentaire,
                               model: apiResponse.model,
                               finishReason: apiResponse.choices.first?.finishReason)
        }

        private func extractScorePayload(from content: String) throws -> CulinaryScorePayload {
            guard let data = firstJSONData(in: content) else {
                throw ScoringServiceError.invalidScorePayload
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let payload = try decoder.decode(CulinaryScorePayload.self, from: data)
            try validateScores(payload)
            return payload
        }

        private func firstJSONData(in text: String) -> Data? {
            if let data = text.data(using: .utf8),
               (try? JSONSerialization.jsonObject(with: data)) != nil {
                return data
            }

            guard let start = text.firstIndex(of: "{") else { return nil }

            var depth = 0
            var endIndex: String.Index?

            for index in text.indices[start...] {
                let char = text[index]
                if char == "{" {
                    depth += 1
                } else if char == "}" {
                    depth -= 1
                    if depth == 0 {
                        endIndex = text.index(after: index)
                        break
                    }
                }
            }

            guard let endIndex else { return nil }
            let jsonSubstring = text[start..<endIndex]
            return String(jsonSubstring).data(using: .utf8)
        }
    }

// MARK: - Aggregations
private extension ScoringService {
    func persist(result: ScoreResult, for entry: ScoreEntry) async throws {
        guard let entryId = entry.id else { return }

        var updates: [String: Any] = [
            "status": ScoreEntry.Status.completed.rawValue,
            "responseJSON": result.rawJSON,
            "scoredAt": FieldValue.serverTimestamp(),
            "score": result.score ?? 0,
            "comment": result.comment ?? "",
            "lastError": FieldValue.delete()
        ]

        try await firestore.collection(entriesCollection).document(entryId).updateData(updates)
        NotificationCenter.default.post(name: .scoresDidUpdate, object: entry.challengeId)
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
        try await firestore.collection(aggregatesCollection)
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

    func openAIAPIKey() -> String? {
        if let environmentKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !environmentKey.isEmpty {
            return environmentKey
        }

        if let bundleKey = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String, !bundleKey.isEmpty {
            return bundleKey
        }

        return nil
    }

    func truncatedPreview(_ value: String, limit: Int = 800) -> String {
        guard value.count > limit else { return value }
        let index = value.index(value.startIndex, offsetBy: limit)
        return "\(value[..<index])…"
    }

    func validateScores(_ payload: CulinaryScorePayload) throws {
        guard (0...10).contains(payload.scoreGlobal) else {
            throw ScoringServiceError.invalidScorePayload
        }
    }
}

// MARK: - OpenAI DTOs
private struct ChatRequest: Encodable {
    var model: String = "gpt-4o-mini"
    var messages: [MultimodalMessage]
    var temperature: Double = 0.2

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case responseFormat = "response_format"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(messages, forKey: .messages)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(["type": "json_object"], forKey: .responseFormat)
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

        enum CodingKeys: String, CodingKey {
            case role
            case content
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            role = try container.decode(String.self, forKey: .role)

            if let textContent = try? container.decode(String.self, forKey: .content) {
                content = textContent
                return
            }

            if var parts = try? container.nestedUnkeyedContainer(forKey: .content) {
                var texts: [String] = []

                while !parts.isAtEnd {
                    if let part = try? parts.decode(ChatContentPart.self), let text = part.text {
                        texts.append(text)
                    } else {
                        _ = try? parts.decode(EmptyDecodable.self)
                    }
                }

                content = texts.joined(separator: "\n")
            } else {
                content = ""
            }
        }
    }
}

private struct MultimodalMessage: Encodable {
    let role: String
    let content: [ContentPart]

    enum ContentPart: Encodable {
        case text(String)
        case imageURL(String)

        enum CodingKeys: String, CodingKey {
            case type
            case text
            case imageURL = "image_url"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let value):
                try container.encode("text", forKey: .type)
                try container.encode(value, forKey: .text)
            case .imageURL(let urlString):
                try container.encode("image_url", forKey: .type)
                try container.encode(["url": urlString], forKey: .imageURL)
            }
        }
    }
}

private struct ChatContentPart: Decodable {
    let type: String
    let text: String?

    enum CodingKeys: String, CodingKey {
        case type
        case text
    }

    struct TextContainer: Decodable {
        let value: String
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)

        if let rawText = try? container.decode(String.self, forKey: .text) {
            text = rawText
        } else if let nested = try? container.decode(TextContainer.self, forKey: .text) {
            text = nested.value
        } else {
            text = nil
        }
    }
}

private struct EmptyDecodable: Decodable {}
