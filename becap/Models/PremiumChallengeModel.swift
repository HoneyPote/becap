//
//  PremiumChallengeModel.swift
//  becap
//
//  Created by OpenAI on 2025-02-14.
//

import Foundation

struct PremiumChallenge: Identifiable, Hashable {
    enum MediaType: Equatable {
        case text(String)
        case video(URL)
    }

    let id: UUID
    let title: String
    let subtitle: String
    let price: Decimal
    let currencyCode: String
    let media: MediaType

    var isUnlocked: Bool = false

    init(id: UUID = UUID(),
         title: String,
         subtitle: String,
         price: Decimal,
         currencyCode: String = "EUR",
         media: MediaType,
         isUnlocked: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.price = price
        self.currencyCode = currencyCode
        self.media = media
        self.isUnlocked = isUnlocked
    }
}

extension PremiumChallenge {
    static let sampleData: [PremiumChallenge] = [
        PremiumChallenge(
            title: "30 jours de gratitude",
            subtitle: "Capture un moment de gratitude par jour pour transformer ta perspective.",
            price: Decimal(string: "4.99") ?? 4.99,
            media: .text("Chaque jour, reçois un guide photo et des affirmations pour te recentrer sur l'essentiel. Ce challenge t'accompagne dans un voyage de gratitude personnelle.")),
        PremiumChallenge(
            title: "Défi Bien-être & Nature",
            subtitle: "Reconnecte-toi à la nature avec des missions photo et audio guidées.",
            price: Decimal(string: "6.99") ?? 6.99,
            media: .video(URL(string: "https://example.com/videos/bien-etre.mp4")!)
        ),
        PremiumChallenge(
            title: "Créativité Express",
            subtitle: "12 jours pour réveiller ta créativité visuelle en 5 minutes par jour.",
            price: Decimal(string: "3.49") ?? 3.49,
            media: .text("Découvre des prompts photo originaux et des astuces pour jouer avec la lumière, les textures et les couleurs."))
    ]
}
