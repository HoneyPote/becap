//
//  CulinaryFeedbackService.swift
//  becap
//
//  Created by OpenAI on 15/05/2024.
//

import Foundation

/// Centralise le prompt et les logs d'audit liés aux évaluations GPT.
final class CulinaryFeedbackService {
    static let shared = CulinaryFeedbackService()

    private let auditLogger = ScoreAuditLogger()

    /// Prompt appliqué à chaque appel GPT pour encadrer la génération.
    let guardrailPrompt: String = {
        [
            "- Tu es un critique culinaire bienveillant qui commente des créations.",
            "- Reste positif et encourageant : mets l'accent sur le goût, la présentation et l'originalité.",
            "- Ne fournis jamais d'évaluation calorique ou nutritionnelle précise (pas de kcal, macros, calculs détaillés).",
            "- Si on te demande des calories, explique gentiment que tu ne peux qu'évoquer des impressions générales (léger, gourmand, généreux...).",
            "- Ne donne pas de conseils médicaux ou de restriction alimentaire. Oriente vers un professionnel de santé si besoin.",
            "- Garde un ton chaleureux, inclusif et respectueux dans toutes tes réponses."
        ].joined(separator: "\n")
    }()

    private init() {}

    /// Construit un prompt complet en ajoutant le contexte du plat décrit par l'utilisateur.
//    func buildPrompt(for dishDescription: String) -> String {
//        """
//        \(guardrailPrompt)
//
//        Détails du plat fourni par l'utilisateur :
//        """
//        \(dishDescription)
//        """
//
//        Donne un court commentaire global et des notes sur 10 pour le goût, la présentation et l'originalité.
//        """
//    }

    /// Enregistre localement l'évaluation et les éventuelles incohérences détectées.
    func recordAudit(evaluation: CulinaryEvaluation, rawModelResponse: String) {
        let flags = detectInconsistencies(from: evaluation, rawModelResponse: rawModelResponse)
        let entry = ScoreAuditEntry(
            evaluation: evaluation,
            guardrailPrompt: guardrailPrompt,
            rawModelResponse: rawModelResponse,
            detectedInconsistencies: flags
        )

        auditLogger.append(entry)
    }

    /// Charge toutes les entrées d'audit sauvegardées sur l'appareil.
    func loadAuditTrail() -> [ScoreAuditEntry] {
        auditLogger.loadEntries()
    }

    private func detectInconsistencies(from evaluation: CulinaryEvaluation, rawModelResponse: String) -> [String] {
        var issues: [String] = []

        let scores = [evaluation.tasteScore, evaluation.presentationScore, evaluation.originalityScore]
        let invalidScores = scores.filter { $0 < 0 || $0 > 10 }
        if !invalidScores.isEmpty {
            issues.append("Scores hors plage attendue 0-10: \(invalidScores.map(String.init).joined(separator: ", "))")
        }

        if rawModelResponse.localizedCaseInsensitiveContains("kcal") || rawModelResponse.localizedCaseInsensitiveContains("calorie") {
            issues.append("Mention calorique détectée malgré le garde-fou")
        }

        if evaluation.generalFeedback.localizedCaseInsensitiveContains("calorie") {
            issues.append("Feedback mentionne des calories")
        }

        return issues
    }
}

// MARK: - Audit logger
final class ScoreAuditLogger {
    private let fileManager = FileManager.default
    private let logFileName = "culinary_score_audit.json"

    func append(_ entry: ScoreAuditEntry) {
        var entries = loadEntries()
        entries.append(entry)
        persist(entries)
    }

    func loadEntries() -> [ScoreAuditEntry] {
        guard let data = try? Data(contentsOf: logURL()) else { return [] }
        return (try? JSONDecoder().decode([ScoreAuditEntry].self, from: data)) ?? []
    }

    // MARK: - Private helpers
    private func persist(_ entries: [ScoreAuditEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: logURL(), options: [.atomic])
        } catch {
            print("❌ Impossible d'enregistrer les logs d'audit: \(error)")
        }
    }

    private func logURL() -> URL {
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        return directory.appendingPathComponent(logFileName)
    }
}
