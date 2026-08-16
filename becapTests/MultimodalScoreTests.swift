import Foundation
import Testing
@testable import becap

struct MultimodalScoreTests {
    @Test func decodesScoringResponse() throws {
        let json = #"{"score":8,"detected_elements":["livre","lecture"],"feedback":"Objectif visible"}"#.data(using: .utf8)!
        let result = try JSONDecoder().decode(MultimodalScore.self, from: json)

        #expect(result.score == 8)
        #expect(result.detectedElements == ["livre", "lecture"])
        #expect(result.feedback == "Objectif visible")
    }

    @Test func clampsScoreToSupportedRange() {
        #expect(MultimodalScore(score: 14, detectedElements: [], feedback: "").score == 10)
        #expect(MultimodalScore(score: -4, detectedElements: [], feedback: "").score == 0)
    }

    @Test func foodScoringRequiresVisibleMealPreparation() {
        let prompt = MultimodalScoringService.shared.scoringPrompt(
            challengeTitle: "Cuisiner un repas",
            category: .food
        )

        #expect(prompt.contains("fruit ou ingrédient brut isolé"))
        #expect(prompt.contains("vaut 0 à 3"))
        #expect(prompt.contains("10 est exceptionnel"))
        #expect(prompt.contains("N'invente jamais une préparation"))
    }
}
