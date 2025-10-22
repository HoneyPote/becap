//
//  ParticipantMedalSection.swift
//  becap
//
//  Created by Adam Mabrouki on 20/07/2025.
//

import SwiftUI

struct MedalDisplayItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let iconName: String
    let count: Int
    let latestDate: Date
}

// TODO: Trop de calculs
// mdr ba t'as cas pas calculer enfoiré
struct ParticipantMedalSection: View {
    let medals: [UserMedal]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(groupedMedals) { medal in
                HStack {
                    MedalIconView(iconName: medal.iconName)
                        .frame(width: 36, height: 36)
                    Text(medal.count > 1 ? "×\(medal.count) \(medal.name)" : medal.name)
                        .font(.system(.body, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)
                    Spacer()
                    Text(shortDate(medal.latestDate))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }

    // Nouveau: on ne touche plus à iconName, on affiche directement ce qu'il y a dans UserMedal
    private var groupedMedals: [MedalDisplayItem] {
        let grouped = Dictionary(grouping: medals, by: \.name)

        return grouped.map { (name, items) in
            MedalDisplayItem(name: name,
                             description: items.first?.description ?? "",
                             iconName: items.first?.iconName ?? "star.fill",
                             count: items.count,
                             latestDate: items.map(\.achievedDate).max() ?? Date())
        }
        .sorted { $0.latestDate > $1.latestDate }
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

/// Ce View choisit l'image importée **ou** le SF Symbol automatiquement
struct MedalIconView: View {
    let iconName: String

    var body: some View {
        // Essaie de charger l'image importée (assets). Si elle existe, l'affiche, sinon passe sur SF Symbol.
        if let uiImage = UIImage(named: iconName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .foregroundColor(.yellow)
        }
    }
}
