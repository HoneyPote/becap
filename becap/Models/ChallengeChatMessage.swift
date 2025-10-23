//
//  ChallengeChatMessage.swift
//  becap
//
//  Created by OpenAI on 06/08/2025.
//

import Foundation
import FirebaseFirestoreSwift

struct ChallengeChatMessage: Identifiable, Codable, Hashable {
    @DocumentID var documentId: String?
    var challengeId: String
    var senderId: String
    var senderName: String
    var content: String
    var createdAt: Date

    var id: String {
        documentId ?? "\(senderId)_\(createdAt.timeIntervalSince1970)"
    }
}
