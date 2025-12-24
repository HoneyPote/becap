//
//  CulinaryPromptBuilder.swift
//  becap
//
//  Created by OpenAI on 14/11/2025.
//

import Foundation

enum CulinaryPromptBuilder {
    static let system = """
    Tu es un jury culinaire exigeant. Évalue chaque plat selon ces critères :
    - equilibre_nutritionnel
    - diversite_ingredients
    - cuisson_technique
    - originalite_saisonnalite

    Règles : les scores doivent être des entiers entre 0 et 10. Le commentaire doit faire 2 à 4 phrases.
    """

    static let outputSchema = """
    Réponds uniquement avec un JSON strict (sans texte autour) et respectant exactement le schéma :
    {
      "score_global": 0,
      "details": {
        "equilibre": 0,
        "diversite": 0,
        "technique": 0,
        "originalite": 0
      },
      "commentaire": ""
    }
    """

    static func userPrompt(dishName: String?, ingredients: [String]?, context: String?) -> String {
        let safeDishName = dishName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? dishName!
            : "Non renseigné"
        let safeIngredients = ingredients?.isEmpty == false
            ? ingredients!.joined(separator: ", ")
            : "Non renseignés"
        let safeContext = context?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? context!
            : "Non renseigné"

        return """
        Plat : \(safeDishName)
        Ingrédients : \(safeIngredients)
        Contexte : \(safeContext)

        Réponds uniquement au format JSON demandé, sans texte additionnel.
        """
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

func buildCulinaryMessages(
    dishDescription: String,
    dishName: String? = nil,
    ingredients: [String]? = nil,
    context: String? = nil
) -> [ChatMessage] {
    let systemMessage = CulinaryPromptBuilder.system + "\n\n" + CulinaryPromptBuilder.outputSchema
    let resolvedContext = context ?? dishDescription
    let userMessage = CulinaryPromptBuilder.userPrompt(
        dishName: dishName,
        ingredients: ingredients,
        context: resolvedContext
    )

    return [
        ChatMessage(role: "system", content: systemMessage),
        ChatMessage(role: "user", content: userMessage)
    ]
}
