//
//  ChallengeIngestionService.swift
//  becap
//
//  Created by OpenAI's assistant on 2024-05-08.
//

import Foundation

enum ChallengeEntryValidationError: LocalizedError {
    case missingParticipant
    case missingTimestamp
    case missingNomPlat
    case missingIngredients
    case missingPhotoURL
    case invalidIngredientCount(Int)

    var errorDescription: String? {
        switch self {
        case .missingParticipant:
            return "Le participant est obligatoire."
        case .missingTimestamp:
            return "Le timestamp de la publication est obligatoire."
        case .missingNomPlat:
            return "Le nom du plat est obligatoire."
        case .missingIngredients:
            return "La liste d'ingrédients est obligatoire."
        case .missingPhotoURL:
            return "L'URL de la photo est obligatoire."
        case .invalidIngredientCount(let count):
            return "Le nombre d'ingrédients (\(count)) dépasse la limite autorisée."
        }
    }
}

protocol ChallengeEntrySource {
    var name: String { get }
    func fetchEntries() async throws -> [ChallengeSourcePayload]
}

protocol SQLClient {
    func execute(_ query: String, parameters: [Any]) async throws
}

final class ChallengeEntryRepository {
    private let client: SQLClient

    init(client: SQLClient) {
        self.client = client
    }

    func ensureSchema() async throws {
        let statement = """
        CREATE TABLE IF NOT EXISTS entries (
            id UUID PRIMARY KEY,
            participant VARCHAR(64) NOT NULL,
            date TIMESTAMPTZ NOT NULL,
            nom VARCHAR(120) NOT NULL,
            ingredients TEXT NOT NULL,
            note_personnelle TEXT,
            url_photo TEXT NOT NULL,
            source_meta JSONB NOT NULL
        );
        """

        try await client.execute(statement, parameters: [])
    }

    func insert(_ entry: ChallengeEntry) async throws {
        let query = """
        INSERT INTO entries (id, participant, date, nom, ingredients, note_personnelle, url_photo, source_meta)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8);
        """

        let parameters: [Any] = [
            entry.id.uuidString,
            entry.participant,
            entry.timestamp,
            entry.nomPlat,
            entry.ingredients.joined(separator: ","),
            entry.notePersonnelle as Any,
            entry.urlPhoto.absoluteString,
            entry.sourceMeta
        ]

        try await client.execute(query, parameters: parameters)
    }
}

final class ChallengeEntryValidator {
    private let participantMaxLength = 64
    private let nomPlatMaxLength = 120
    private let noteMaxLength = 500
    private let ingredientMaxLength = 80
    private let ingredientsMaxCount = 30
    private let allowedCharacters = CharacterSet.alphanumerics
        .union(.whitespacesAndNewlines)
        .union(CharacterSet(charactersIn: "-'_.,;:/@éèêàçùïîôöâäëüÉÈÀÇÙÂÊÎÔÛäöüß"))

    func validate(_ payload: ChallengeSourcePayload) throws -> ChallengeEntry {
        guard let participant = sanitized(value: payload.participant, maxLength: participantMaxLength) else {
            throw ChallengeEntryValidationError.missingParticipant
        }

        guard let timestamp = payload.timestamp else {
            throw ChallengeEntryValidationError.missingTimestamp
        }

        guard let nomPlat = sanitized(value: payload.nomPlat, maxLength: nomPlatMaxLength) else {
            throw ChallengeEntryValidationError.missingNomPlat
        }

        guard let rawIngredients = payload.ingredients else {
            throw ChallengeEntryValidationError.missingIngredients
        }

        if rawIngredients.count > ingredientsMaxCount {
            throw ChallengeEntryValidationError.invalidIngredientCount(rawIngredients.count)
        }

        let ingredients = rawIngredients
            .compactMap { sanitized(value: $0, maxLength: ingredientMaxLength) }
            .filter { !$0.isEmpty }

        guard !ingredients.isEmpty else {
            throw ChallengeEntryValidationError.missingIngredients
        }

        guard let url = payload.urlPhoto else {
            throw ChallengeEntryValidationError.missingPhotoURL
        }

        let note = sanitized(value: payload.notePersonnelle, maxLength: noteMaxLength)

        return ChallengeEntry(
            id: UUID(),
            participant: participant,
            timestamp: timestamp,
            nomPlat: nomPlat,
            ingredients: ingredients,
            notePersonnelle: note,
            urlPhoto: url,
            sourceMeta: payload.sourceMeta
        )
    }

    private func sanitized(value: String?, maxLength: Int) -> String? {
        guard let value else { return nil }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let filteredScalars = trimmed.unicodeScalars.filter { allowedCharacters.contains($0) }
        let cleaned = String(String.UnicodeScalarView(filteredScalars))

        if cleaned.count > maxLength {
            let endIndex = cleaned.index(cleaned.startIndex, offsetBy: maxLength)
            return String(cleaned[..<endIndex])
        }

        return cleaned
    }
}

final class ChallengeIngestionService {
    private let sources: [ChallengeEntrySource]
    private let validator: ChallengeEntryValidator
    private let repository: ChallengeEntryRepository

    init(sources: [ChallengeEntrySource], validator: ChallengeEntryValidator = ChallengeEntryValidator(), repository: ChallengeEntryRepository) {
        self.sources = sources
        self.validator = validator
        self.repository = repository
    }

    func ingestScheduledSources() async -> [ChallengeIngestionResult] {
        await withTaskGroup(of: [ChallengeIngestionResult].self) { group in
            for source in sources {
                group.addTask { [validator, repository] in
                    do {
                        let rawEntries = try await source.fetchEntries()
                        try await repository.ensureSchema()

                        var results: [ChallengeIngestionResult] = []
                        for raw in rawEntries {
                            do {
                                let result = try await self.validateAndPersist(rawPayload: raw, validator: validator, repository: repository)
                                results.append(result)
                            } catch {
                                results.append(ChallengeIngestionResult(entry: nil, error: error))
                            }
                        }

                        return results
                    } catch {
                        return [ChallengeIngestionResult(entry: nil, error: error)]
                    }
                }
            }

            var aggregated: [ChallengeIngestionResult] = []
            for await result in group {
                aggregated.append(contentsOf: result)
            }
            return aggregated
        }
    }

    func ingestWebhookPayload(_ payload: ChallengeSourcePayload) async -> ChallengeIngestionResult {
        do {
            try await repository.ensureSchema()
            return try await validateAndPersist(rawPayload: payload, validator: validator, repository: repository)
        } catch {
            return ChallengeIngestionResult(entry: nil, error: error)
        }
    }

    private func validateAndPersist(rawPayload: ChallengeSourcePayload, validator: ChallengeEntryValidator, repository: ChallengeEntryRepository) async throws -> ChallengeIngestionResult {
        let entry = try validator.validate(rawPayload)
        try await repository.insert(entry)
        return ChallengeIngestionResult(entry: entry, error: nil)
    }
}
