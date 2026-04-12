//
//  DailyPrompt.swift
//  becap
//
//  Created by Codex on 17/02/2026.
//

import Foundation
import FirebaseFirestore

struct DailyPrompt: Codable, Hashable {
    var word: String
    var theme: String?
}

struct SeenPrompt: Codable {
    @ServerTimestamp var seenAt: Timestamp?
}

