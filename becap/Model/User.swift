//
//  User.swift
//  becap
//
//  Created by Victor Derveaux on 20/07/2025.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var name: String
}
