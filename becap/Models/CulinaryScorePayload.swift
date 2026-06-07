//
//  CulinaryScorePayload.swift
//  becap
//
//  Created by OpenAI on 14/11/2025.
//

import Foundation

struct CulinaryScorePayload: Decodable {
    let scoreGlobal: Double
    let commentaire: String
    let ingredientsVisibles: [String]?
    let remarques: [String]?
}
