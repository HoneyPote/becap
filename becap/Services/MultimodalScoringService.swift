import Foundation
import UIKit

enum MultimodalScoringError: LocalizedError {
    case invalidImage
    case invalidResponse
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "La photo ne peut pas être analysée."
        case .invalidResponse: return "La réponse du service de scoring est invalide."
        case .server(let statusCode): return "Le service de scoring a répondu avec le code \(statusCode)."
        }
    }
}

protocol MultimodalScoring {
    func score(image: UIImage, challengeTitle: String, category: ChallengeCategory?) async throws -> MultimodalScore
}

/// Envoie une version compressée de la photo à la Cloud Function qui protège la clé OpenAI.
/// La clé n'est volontairement jamais embarquée dans l'application.
final class MultimodalScoringService: MultimodalScoring {
    static let shared = MultimodalScoringService()

    private let session: URLSession
    private let endpoint: URL

    init(session: URLSession = .shared,
         endpoint: URL = URL(string: "https://us-central1-honeypote-becap.cloudfunctions.net/scoreChallengePhoto")!) {
        self.session = session
        self.endpoint = endpoint
    }

    func score(image: UIImage, challengeTitle: String, category: ChallengeCategory?) async throws -> MultimodalScore {
        let resizedImage = image.resized(toMaxWidth: 1024)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.72) else {
            throw MultimodalScoringError.invalidImage
        }

        let payload = RequestPayload(imageBase64: imageData.base64EncodedString(),
                                     challengeTitle: challengeTitle,
                                     category: category?.rawValue)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MultimodalScoringError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw MultimodalScoringError.server(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(MultimodalScore.self, from: data)
        } catch {
            throw MultimodalScoringError.invalidResponse
        }
    }

    private struct RequestPayload: Encodable {
        let imageBase64: String
        let challengeTitle: String
        let category: String?

        enum CodingKeys: String, CodingKey {
            case imageBase64 = "image_base64"
            case challengeTitle = "challenge_title"
            case category
        }
    }
}
