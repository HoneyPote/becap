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
    let currentUserUsedJoker: Bool
    let isToday: Bool
    let isWithinChallenge: Bool
    let isSelected: Bool
    let tap: () -> Void

    private var hasPhotos: Bool { photoCount > 0 }
    private var hasJokerUsage: Bool { jokerCount > 0 }

    var body: some View {
        Button {
            if hasPhotos || hasJokerUsage { Haptics.lightTap() }
            tap()
        } label: {
            ZStack {
                // fond
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(backgroundFill)

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
                        .foregroundColor(titleColor)
                    Spacer(minLength: 0)
                }
                .padding(.bottom, -8)
            }
            .frame(height: 72)
            .opacity(isWithinChallenge ? 1.0 : 0.38)
            // badge photos en haut-droite
            .overlay(alignment: .topTrailing) {
                VStack(alignment: .trailing, spacing: 4) {
                    if hasPhotos {
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
                    }

                    if hasJokerUsage {
                        Circle()
                            .fill(jokerBadgeGradient)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.85), lineWidth: 1)
                            )
                            .shadow(color: Color.purple.opacity(0.35), radius: 2, x: 0, y: 1)
                            .accessibilityLabel("Joker utilisé ce jour")
                            .accessibilityAddTraits(.isStaticText)
                    }
                }
                .padding(.top, 4)
                .padding(.trailing, 4)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isWithinChallenge)
    }
}

private extension DayCell {
    var backgroundFill: LinearGradient {
        if currentUserUsedJoker {
            return LinearGradient(colors: [
                Color(red: 0.69, green: 0.38, blue: 0.96),
                Color(red: 0.46, green: 0.22, blue: 0.82)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        let baseColor: Color = isToday ? Color.green.opacity(0.85)
                                       : Color.white.opacity(isWithinChallenge ? 0.38 : 0.23)

        return LinearGradient(colors: [baseColor, baseColor], startPoint: .top, endPoint: .bottom)
    }

    var titleColor: Color {
        if currentUserUsedJoker { return .white }
        if isToday { return .black }
        return isWithinChallenge ? .white : .white.opacity(0.45)
    }

    var jokerBadgeGradient: LinearGradient {
        LinearGradient(colors: [
            Color(red: 0.78, green: 0.47, blue: 0.98),
            Color(red: 0.61, green: 0.29, blue: 0.93)
        ], startPoint: .top, endPoint: .bottom)
    }
}
