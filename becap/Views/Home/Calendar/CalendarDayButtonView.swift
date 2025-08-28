//
//  CalendarDayButtonView.swift
//  becap
//
//  Created by Victor Derveaux on 15/08/2025.
//

import SwiftUI

struct CalendarDayButtonView: View {
    let cell: CalendarDetailCell
    let action: () -> Void

    var isEnabled: Bool

    var body: some View {
        Button(action: {
            if isEnabled { action() }
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundColor(.white)

                    if cell.isToday {
                        Text("Aujourd’hui")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.85))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("\(cell.photos.count) photo(s)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.caption)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cell.isToday ? Color.green.opacity(0.25) : Color.white.opacity(0.08))
            )
        }
        .disabled(!isEnabled)
    }

    var formattedDate: String {
        let df = DateFormatter()
        df.dateStyle = .long
        df.locale = Locale(identifier: "fr_FR")

        return df.string(from: cell.date)
    }
}
