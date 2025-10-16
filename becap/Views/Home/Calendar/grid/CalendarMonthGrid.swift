//
//  CalendarDaysList.swift
//  becap
//
//  Created by Adam Mabrouki on 04/09/2025.
//  Updated by ChatGPT on 13/06/2024.
//

import SwiftUI

struct CalendarDaysList: View {
    let cells: [CalendarDetailCell]
    let selectedCell: CalendarDetailCell?
    let onSelect: (CalendarDetailCell) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(cells.enumerated()), id: \.element.id) { index, cell in
                    CalendarDayRow(dayNumber: index + 1,
                                   cell: cell,
                                   isSelected: selectedCell?.id == cell.id,
                                   onTap: { onSelect(cell) })
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
        }
    }
}

private struct CalendarDayRow: View {
    let dayNumber: Int
    let cell: CalendarDetailCell
    let isSelected: Bool
    let onTap: () -> Void

    private var hasPhotos: Bool { !cell.photos.isEmpty }

    var body: some View {
        Button {
            if hasPhotos {
                onTap()
            }
        } label: {
            HStack(spacing: 12) {
                DayNumberBadge(dayNumber: dayNumber, isToday: cell.isToday)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Jour \(dayNumber)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(Self.dateFormatter.string(from: cell.date).capitalized)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                }

                Spacer(minLength: 12)

                if cell.isToday {
                    Text("Aujourd'hui")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.9))
                        .clipShape(Capsule())
                }

                if hasPhotos {
                    Label("\(cell.photos.count)", systemImage: "camera.fill")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                } else {
                    Text("Aucune photo")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(background)
            .overlay(border)
        }
        .buttonStyle(.plain)
        .opacity(hasPhotos ? 1.0 : 0.6)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                cell.isToday
                ? Color.white.opacity(0.2)
                : Color.white.opacity(0.08)
            )
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(isSelected ? Color.white.opacity(0.9) : Color.white.opacity(0.18), lineWidth: isSelected ? 1.4 : 0.7)
    }

    private struct DayNumberBadge: View {
        let dayNumber: Int
        let isToday: Bool

        var body: some View {
            ZStack {
                Circle()
                    .fill(isToday ? Color.green.opacity(0.9) : Color.white.opacity(0.12))
                    .frame(width: 42, height: 42)

                Text("\(dayNumber)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isToday ? .black : .white)
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
        return formatter
    }()
}
