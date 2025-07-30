//
//  ParticipantMedalSection.swift
//  becap
//
//  Created by Adam Mabrouki on 26/07/2025.
//
import SwiftUI

struct ParticipantMedalSection: View {
    let medals: [UserMedal]

    struct MedalDisplayItem: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let iconName: String
        let count: Int
        let latestDate: Date
    }

    private var groupedMedals: [MedalDisplayItem] {
        let grouped = Dictionary(grouping: medals, by: \.name)
        return grouped.map { (name, items) in
            MedalDisplayItem(
                name: name,
                description: items.first?.description ?? "",
                iconName: iconName(for: name),
                count: items.count,
                latestDate: items.map(\.achievedDate).max() ?? Date()
            )
        }
        .sorted { $0.latestDate > $1.latestDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(groupedMedals) { medal in
                HStack {
                    Image(systemName: medal.iconName)
                        .foregroundColor(.yellow)
                    Text(medal.count > 1 ? "×\(medal.count) \(medal.name) " : medal.name)
                        .fontWeight(.medium)
                    Spacer()
                    Text(shortDate(medal.latestDate))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private func iconName(for name: String) -> String {
        switch name {
        case "🔥 Streak 3": return "flame.fill"
        case "🔥 Streak 7": return "flame.circle.fill"
        case "🏁 Finisher": return "flag.checkered"
        case "Motivation": return "star"
        case "Double Beast": return "trophy.fill"
        default: return "star.fill"
        }
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
