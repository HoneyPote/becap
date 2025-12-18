//
//  CreatorUpdate.swift
//  becap
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//
import Foundation
import FirebaseFirestore

struct CreatorUpdate: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var authorId: String
    var createdAt: Date
    var text: String
    var mediaUrl: String?
    var mediaType: String?

    init(id: String? = nil,
         authorId: String,
         createdAt: Date = Date(),
         text: String,
         mediaUrl: String? = nil,
         mediaType: String? = nil) {
        self.id = id
        self.authorId = authorId
        self.createdAt = createdAt
        self.text = text
        self.mediaUrl = mediaUrl
        self.mediaType = mediaType
    }
}
