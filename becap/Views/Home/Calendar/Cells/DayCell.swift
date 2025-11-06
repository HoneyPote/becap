//
//  DayCell.swift
//  becap
//
//  Created by Adam Mabrouki on 04/09/2025.
//

import SwiftUI
import UIKit

enum Haptics {
    static func lightTap() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred(intensity: 0.8)
    }
}


struct DayCell: View {
    let date: Date
    let dayNumber: Int          // ⬅️ nouveau : n° du jour de défi
    let photoCount: Int
    let jokerCount: Int
    let isToday: Bool
    let isWithinChallenge: Bool
    let isSelected: Bool
    let tap: () -> Void

    private var photoCountIsNil: Bool { photoCount == 0 }
    private var hasJokerUsage: Bool { jokerCount > 0 }

    var body: some View {
        Button {
            if !photoCountIsNil || hasJokerUsage { Haptics.lightTap() }
            tap()
        } label: {
            ZStack {
                // fond
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isToday ? Color.green.opacity(0.85)
                                  : Color.white.opacity(isWithinChallenge ? 0.08 : 0.03))

                // anneau sélection
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1.4)
                }

                // *** AU CENTRE: numéro DU DÉFI ***
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Text("\(dayNumber)") // <-- au lieu du jour du mois
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(isToday ? .black : (isWithinChallenge ? .white : .white.opacity(0.45)))
                    Spacer(minLength: 0)
                }
                .padding(.bottom, -8)
            }
            .frame(height: 72)
            .opacity(isWithinChallenge ? 1.0 : 0.38)
            // badge photos en haut-droite
            .overlay(alignment: .topTrailing) {
                if !photoCountIsNil {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(photoCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.25))
                    .clipShape(Capsule())
                    .padding(4)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if hasJokerUsage {
                    HStack(spacing: 4) {
                        JokerIconView(size: 20,
                                      isDimmed: true)
                            .frame(width: 20, height: 20)
                        Text("\(jokerCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.28))
                    .clipShape(Capsule())
                    .padding(.leading, 4)
                    .padding(.bottom, 6)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isWithinChallenge)
    }
}
