import Foundation
import Testing
import UIKit
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

    @Test func scoringUsesCloudFunctionWithoutOpenAIKey() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ScoringURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = URL(string: "https://example.test/scoreChallengePhoto")!
        let service = MultimodalScoringService(session: session, endpoint: endpoint)

        ScoringURLProtocol.requestHandler = { request in
            #expect(request.url == endpoint)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let body = try #require(request.httpBody)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["model"] as? String == "gpt-4.1-mini")

            let score = #"{\"score\":8,\"detected_elements\":[\"livre\"],\"feedback\":\"Objectif visible\"}"#
            let response = try JSONSerialization.data(withJSONObject: [
                "output": [["content": [["text": score]]]]
            ])
            return (HTTPURLResponse(url: endpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!, response)
        }

        let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
            UIColor.white.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
        let result = try await service.score(image: image, challengeTitle: "Lire", category: .reading)

        #expect(result.score == 8)
        #expect(result.detectedElements == ["livre"])
    }
}

private final class ScoringURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let handler = try #require(Self.requestHandler)
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
