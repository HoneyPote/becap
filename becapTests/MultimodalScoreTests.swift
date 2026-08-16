import Foundation
import Testing
@testable import becap

struct MultimodalScoreTests {
    @Test func decodesScoringResponse() throws {
        let json = #"{"score":84,"detected_elements":["livre","lecture"],"feedback":"Objectif visible"}"#.data(using: .utf8)!
        let result = try JSONDecoder().decode(MultimodalScore.self, from: json)

        #expect(result.score == 84)
        #expect(result.detectedElements == ["livre", "lecture"])
        #expect(result.feedback == "Objectif visible")
    }

    @Test func clampsScoreToSupportedRange() {
        #expect(MultimodalScore(score: 140, detectedElements: [], feedback: "").score == 100)
        #expect(MultimodalScore(score: -4, detectedElements: [], feedback: "").score == 0)
    }
}
