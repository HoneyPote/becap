//
//  ChallengeEnrollment.swift
//  becap
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//
//  Architecture overview (payments v2)
//  -----------------------------------
//  - Firestore hosts a subcollection per challenge: challenges/{challengeId}/enrollments/{userId}.
//  - Each enrollment stores the payment provider + status coming from Stripe webhooks.
//  - The client listens to enrollments to derive lock/unlock state instead of trusting local Apple Pay callbacks.
//  - Payments are initiated through a Cloud Function (Stripe PaymentIntent), confirmed via Stripe webhook, then
//    reflected in enrollment.paymentStatus which drives the UI.

import Foundation
import FirebaseFirestore

enum EnrollmentPaymentStatus: String, Codable {
    case free
    case pending
    case paid
    case failed
}

struct ChallengeEnrollment: Identifiable, Codable, Equatable {
    @DocumentID private var _id: String?
    var id: String { _id ?? userId }

    let userId: String
    let challengeId: String
    var createdAt: Date
    var lastUpdatedAt: Date
    var paymentStatus: EnrollmentPaymentStatus
    var paymentProvider: String?
    var paymentIntentId: String?
    var amountCents: Int?
    var currency: String?

    init(userId: String,
         challengeId: String,
         createdAt: Date = Date(),
         lastUpdatedAt: Date = Date(),
         paymentStatus: EnrollmentPaymentStatus = .pending,
         paymentProvider: String? = nil,
         paymentIntentId: String? = nil,
         amountCents: Int? = nil,
         currency: String? = nil) {
        self.userId = userId
        self.challengeId = challengeId
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
        self.paymentStatus = paymentStatus
        self.paymentProvider = paymentProvider
        self.paymentIntentId = paymentIntentId
        self.amountCents = amountCents
        self.currency = currency
    }
}

extension ChallengeEnrollment {
    var isPaid: Bool { paymentStatus == .paid || paymentStatus == .free }
    var isPending: Bool { paymentStatus == .pending }
}
