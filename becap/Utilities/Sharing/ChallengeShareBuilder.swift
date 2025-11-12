import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum ChallengeShareBuilder {
    private static let deepLinkScheme = "becap"
    private static let deepLinkHost = "join"

    static func makeShareItems(for challenge: Challenge) -> [Any]? {
        let code = challenge.code ?? ""
        let linkURL = deepLinkURL(for: challenge, code: code)

        var parts: [String] = [
            "✨ Découvre \"\(challenge.title)\" sur Becap",
            "",
            "Un calendrier collaboratif pour garder le cap ensemble et célébrer vos réussites quotidiennes."
        ]

        if let linkURL { parts += ["", "➡️ Accès direct : \(linkURL.absoluteString)"] }

        let message = parts.joined(separator: "\n")

        #if canImport(UIKit)
        var items: [Any] = []

        if let image = UIImage(named: "epicPic") {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("becap-share-epic.jpg")

            if let data = image.jpegData(compressionQuality: 0.92) {
                do {
                    try data.write(to: tempURL, options: .atomic)
                    items.append(tempURL)
                } catch {
                    print("⚠️ Impossible d’écrire l’image temporaire :", error)
                    items.append(image)
                }
            } else {
                items.append(image)
            }
        } else {
            print("⚠️ UIImage(named: \"epicPic\") est introuvable — vérifie l’asset & sa Target Membership")
        }

        items.append(message)

        if let linkURL { items.append(linkURL) }

        return items.isEmpty ? nil : items
        #else
        return [message, linkURL as Any].compactMap { $0 }
        #endif
    }

    private static func deepLinkURL(for challenge: Challenge, code: String) -> URL? {
        var components = URLComponents()
        components.scheme = deepLinkScheme
        components.host = deepLinkHost
        components.path = ""

        var queryItems: [URLQueryItem] = []
        if !code.isEmpty {
            queryItems.append(URLQueryItem(name: "code", value: code))
        }

        queryItems.append(URLQueryItem(name: "challengeId", value: challenge.id))

        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }
}
