//
//  ChallengeJokerConfiguration.swift
//  becap
//
//  Created by Adam Mabrouki on 09/08/2025.
//

import Foundation

// TODO: A DELETE
struct ChallengeJokerConfiguration: Codable, Hashable {
    /// Number of jokers every participant receives when joining the challenge.
    var jokersPerParticipant: Int

    init(jokersPerParticipant: Int) {
        self.jokersPerParticipant = max(0, jokersPerParticipant)
    }
}
