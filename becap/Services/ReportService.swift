//
//  ReportService.swift
//  becap
//
//  Created by OpenAI on 13/08/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

protocol ReportServiceProtocol {
    func submitReport(_ report: ContentReport) async throws
}

final class ReportService: ReportServiceProtocol {
    static let shared = ReportService()

    private let firestore = Firestore.firestore()
    private let collectionName = "reports"

    private init() {}

    func submitReport(_ report: ContentReport) async throws {
        let data = try Firestore.Encoder().encode(report)

        try await firestore.collection(collectionName).addDocument(data: data)
    }
}
