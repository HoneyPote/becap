//
//  PhotoCommentModel.swift
//  becap
//
//  Created by Adam Mabrouki on 06/08/2025.
//

import Foundation
import FirebaseFirestore

struct PhotoCommentModel: Identifiable, Codable, Equatable{
    @DocumentID var id: String?
    let userId: String
    let userName: String
    let content: String
    let timestamp: Date
}
