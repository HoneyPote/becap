//
//  PostCommentModel.swift
//  becap
//
//  Created by Adam Mabrouki on 06/08/2025.
//

import Foundation
import FirebaseFirestore

struct PostCommentModel: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let userName: String
    let content: String
    let timestamp: Date
}
