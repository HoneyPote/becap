//
//  ParticipantJokerProgress.swift
//  becap
//
//  Created by Adam Mabrouki on 09/08/2025.
//

import Foundation

struct ParticipantJokerProgress: Codable, Hashable {
    var total: Int
    var usages: [JokerUsage]

    init(total: Int, usages: [JokerUsage] = []) {
        self.total = max(0, total)
        self.usages = usages
    }

    var confirmedUsages: [JokerUsage] {
        usages.filter { $0.status == .confirmed }
    }

    var remaining: Int {
        max(0, total - confirmedUsages.count)
    }

    mutating func jokerUsageIsRegistered(on date: Date,
                                         postId: String?,
                                         declaredByAuthor: Bool,
                                         voters: [String]) -> Bool {
        guard remaining > 0 else { return false }

        if let postId, let index = usages.firstIndex(where: { $0.postId == postId }) {
            var usage = usages[index]
            usage.voters = voters
            usage.declaredByAuthor = declaredByAuthor
            usage.status = .confirmed
            usage.confirmedAt = Date()
            usages[index] = usage
            return true
        }

        let usage = JokerUsage(date: date,
                               postId: postId,
                               declaredByAuthor: declaredByAuthor,
                               voters: voters,
                               status: .confirmed,
                               confirmedAt: Date())
        usages.append(usage)
        return true
    }

    mutating func removeUsage(withPostId postId: String?) {
        guard let postId else { return }
        usages.removeAll { $0.postId == postId }
    }
}
