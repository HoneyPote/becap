import Combine
import Foundation

final class DeepLinkRouter: ObservableObject {
    @Published var pendingJoinCode: String?
    @Published var showJoinSheet: Bool
    @Published var pendingCalendarChallengeId: String?

    init(pendingJoinCode: String? = nil,
         showJoinSheet: Bool = false,
         pendingCalendarChallengeId: String? = nil) {
        self.pendingJoinCode = pendingJoinCode
        self.showJoinSheet = showJoinSheet
        self.pendingCalendarChallengeId = pendingCalendarChallengeId
    }

    func handle(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let payload = Self.extractJoinPayload(from: components) else { return }

        DispatchQueue.main.async {
            if let challengeId = payload.challengeId, !challengeId.isEmpty {
                self.pendingCalendarChallengeId = challengeId
                self.showJoinSheet = false
            }

            if let code = payload.code, !code.isEmpty {
                self.pendingJoinCode = code
                if payload.challengeId == nil {
                    self.showJoinSheet = true
                }
            }
        }
    }

    func clearJoin() {
        pendingJoinCode = nil
        showJoinSheet = false
    }

    func clearChallengeNavigation() {
        pendingCalendarChallengeId = nil
    }
}

private extension DeepLinkRouter {
    static func extractJoinPayload(from components: URLComponents) -> (code: String?, challengeId: String?)? {
        let scheme = components.scheme?.lowercased()
        let host = components.host?.lowercased()
        let path = components.path.lowercased()

        let isCustomLink = scheme == "becap" && host == "join"
        let isUniversalLink = (scheme == "https" || scheme == "http") &&
            (host == "becap.app" || host == "www.becap.app") &&
            (path == "/join" || path.hasPrefix("/join/"))

        guard isCustomLink || isUniversalLink else { return nil }

        let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        let challengeId = components.queryItems?.first(where: { $0.name == "challengeId" })?.value
        return (code: code, challengeId: challengeId)
    }
}
