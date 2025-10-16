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

// TODO: Beaucoup de calcul et de variable stockées dans la vue, à voir si besoin de passer par petit VM
struct DayCell: View {
    let date: Date
    let photoCount: Int
    let isToday: Bool
    let isWithinChallenge: Bool
    let isSelected: Bool
    let tap: () -> Void
    let calendar = Calendar.current

    var photoCountIsNil: Bool {
        photoCount == 0
    }

    var body: some View {
        Button {
            if !photoCountIsNil {
                Haptics.lightTap()
            }
            tap()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isToday ? Color.green.opacity(0.85) : Color.white.opacity(isWithinChallenge ? 0.08 : 0.03))

                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1.4)
                }

                VStack(spacing: .zero) {
                    Spacer()
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(isToday ? .black : (isWithinChallenge ? .white : .white.opacity(0.45)))
                    Spacer()
                }
                .padding(.bottom, -8)
            }
            .frame(height: 54)
            .opacity(isWithinChallenge ? 1.0 : 0.38)
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
        }
        .buttonStyle(.plain)
        .disabled(!isWithinChallenge)
    }
}
