//
// BecapSecrets.swift
//  becap
//
//  Created by OpenAI on 14/11/2025.
//

import Foundation

enum BecapSecrets {
    /// Attempts to resolve the OpenAI API key from environment variables or the app bundle.
    /// - Returns: The API key if found, otherwise `nil`.
    static var openAIAPIKey: String? {
        if let environmentKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !environmentKey.isEmpty {
            return environmentKey
        }

        if let bundleKey = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String, !bundleKey.isEmpty {
            return bundleKey
        }

        return nil
    }
}
