//
//  ChallengeChatMessage.swift
//  becap
//
//  Created by OpenAI on 06/08/2025.
//

import Foundation
import FirebaseFirestore

struct ChallengeChatMessage: Identifiable, Codable, Hashable {
    @DocumentID var documentId: String?
    var challengeId: String
    var senderId: String
    var senderName: String
    var content: String
    var createdAt: Date
    var reactions: [String: [String]]

    enum CodingKeys: String, CodingKey {
        case documentId
        case challengeId
        case senderId
        case senderName
        case content
        case createdAt
        case reactions
    }

    init(documentId: String? = nil,
         challengeId: String,
         senderId: String,
         senderName: String,
         content: String,
         createdAt: Date,
         reactions: [String: [String]] = [:]) {
        self.documentId = documentId
        self.challengeId = challengeId
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.createdAt = createdAt
        self.reactions = reactions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        documentId = try container.decodeIfPresent(String.self, forKey: .documentId)
        challengeId = try container.decode(String.self, forKey: .challengeId)
        senderId = try container.decode(String.self, forKey: .senderId)
        senderName = try container.decode(String.self, forKey: .senderName)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        reactions = try container.decodeIfPresent([String: [String]].self, forKey: .reactions) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(documentId, forKey: .documentId)
        try container.encode(challengeId, forKey: .challengeId)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(senderName, forKey: .senderName)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(reactions, forKey: .reactions)
    }

    var id: String {
        documentId ?? "\(senderId)_\(createdAt.timeIntervalSince1970)"
    }
}
