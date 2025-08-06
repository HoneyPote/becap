//
//  MedalsSection.swift
//  becap
//
//  Created by Adam Mabrouki on 06/08/2025.
//
import SwiftUI

 struct MedalsSection: View {
    let medals: [UserMedal]

    var uniqueMedals: [UserMedal] {
        medals.unique(by: \.iconName)
    }

    var body: some View {
        if !uniqueMedals.isEmpty {
            VStack(spacing: 2) {
                Text("Médailles obtenues par le joueur:")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.83))
                HStack(spacing: 6) {
                    ForEach(uniqueMedals, id: \.iconName) { medal in
                        MedalIconView(iconName: medal.iconName)
                            .frame(width: 28, height: 28)
                            .shadow(color: Color.black.opacity(0.13), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .padding(.top, 4)
        }
    }
}
