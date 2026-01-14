//
//  ContentReport.swift
//  becap
//
//  Created by Adam Mabrouki on 13/08/2025.
//

import Foundation
import FirebaseFirestore

enum ContentReportReason: String, Codable, CaseIterable, Identifiable {
    case nudity
    case harassment
    case hateSpeech
    case illegalActivity
    case spam
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nudity: return "Contenu sexuel ou explicite"
        case .harassment: return "Harcèlement ou intimidation"
        case .hateSpeech: return "Discours haineux"
        case .illegalActivity: return "Activité illégale ou dangereuse"
        case .spam: return "Spam ou arnaque"
        case .other: return "Autre motif"
        }
    }
}

struct ContentReport: Codable, Identifiable {
    @DocumentID var id: String?
    let challengeId: String?
    let challengeTitle: String
    let reporterId: String?
    let reporterName: String
    let reason: ContentReportReason
    let details: String?
    let createdAt: Date
}
