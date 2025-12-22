//
//  CulinaryScorePayload.swift
//  becap
//
//  Created by OpenAI on 14/11/2025.
//

import Foundation

struct CulinaryScorePayload: Decodable {
    let scoreGlobal: Int
    let details: Details
    let commentaire: String

    struct Details: Decodable {
        let equilibre: Int
        let diversite: Int
        let technique: Int
        let originalite: Int
    }
}
