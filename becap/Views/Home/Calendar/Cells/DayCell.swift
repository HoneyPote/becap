//
//  DayCell.swift
//  becap
//
//  Created by Adam Mabrouki on 04/09/2025.
//

import SwiftUI

struct DayCell: View {
    let date: Date
    let dayNumber: Int
    let currentUserUsedJoker: Bool
    let isToday: Bool
    let isSelected: Bool
    let tap: () -> Void

    var body: some View {
        Button {
            tap()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(backgroundFill)

                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1.4)
                }

                VStack(spacing: 0) {
                    Spacer(minLength: 12)
                    Text("Jour")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .padding(.bottom, 3)
                    Text("\(dayNumber)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(titleColor)
                    Spacer(minLength: 0)
                    Text("\(formattedDate(date))")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(titleColor)
                }
                .padding(.bottom, 5)
            }
            .frame(height: 72)
        }
        .buttonStyle(.hapticPlain)
    }

    func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "d MMM"
        df.locale = Locale(identifier: "fr_FR")

        return df.string(from: date)
    }
}

private extension DayCell {
    var backgroundFill: LinearGradient {
        if currentUserUsedJoker {
            return LinearGradient(colors: [Color(red: 0.69, green: 0.38, blue: 0.96),
                                           Color(red: 0.46, green: 0.22, blue: 0.82)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        var baseColor: Color = isToday ? Color.green.opacity(0.85) : Color.white.opacity(0.55)
        baseColor = date < Date() ? baseColor : Color.white.opacity(0.30)

        return LinearGradient(colors: [baseColor, baseColor], startPoint: .top, endPoint: .bottom)
    }

    var titleColor: Color {
        if currentUserUsedJoker {
            return .white
        }
        return date > Date() ? .white.opacity(0.55) : .white
    }
}
