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
        let isUniversalLink = (scheme == UniversalLinkConfiguration.scheme || scheme == "http") &&
            UniversalLinkConfiguration.matches(host: host) &&
            (path == UniversalLinkConfiguration.joinPath || path.hasPrefix(UniversalLinkConfiguration.joinPath + "/"))

        guard isCustomLink || isUniversalLink else { return nil }

        let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        let challengeId = components.queryItems?.first(where: { $0.name == "challengeId" })?.value
        return (code: code, challengeId: challengeId)
    }
}

enum UniversalLinkConfiguration {
    static let scheme = "https"
    static let joinPath = "/join"

    private static let defaultHosts = ["becap.app", "www.becap.app", "becap.web.app"]

    static let hosts: [String] = {
        guard let configured = Bundle.main.object(forInfoDictionaryKey: "BECUniversalLinkHosts") as? [String] else {
            return defaultHosts
        }

        let sanitized = configured
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        return sanitized.isEmpty ? defaultHosts : sanitized
    }()

    static var primaryHost: String {
        hosts.first ?? defaultHosts[0]
    }

    static func fallbackHost(excluding host: String) -> String? {
        hosts.first(where: { $0 != host })
    }

    static func matches(host: String?) -> Bool {
        guard let host else { return false }
        return hosts.contains(host)
    }
}
