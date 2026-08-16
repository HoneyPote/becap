import Foundation

/// Résultat explicable renvoyé par la pipeline de scoring multimodal.
struct MultimodalScore: Codable, Hashable {
    let score: Int
    let detectedElements: [String]
    let feedback: String

    enum CodingKeys: String, CodingKey {
        case score
        case detectedElements = "detected_elements"
        case feedback
    }

    init(score: Int, detectedElements: [String], feedback: String) {
        self.score = min(max(score, 0), 10)
        self.detectedElements = detectedElements
        self.feedback = feedback
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(score: try container.decode(Int.self, forKey: .score),
                  detectedElements: try container.decodeIfPresent([String].self, forKey: .detectedElements) ?? [],
                  feedback: try container.decodeIfPresent(String.self, forKey: .feedback) ?? "")
    }
}
