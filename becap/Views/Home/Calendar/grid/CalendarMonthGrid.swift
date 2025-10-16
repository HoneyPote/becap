//
//  CalendarMonthGrid.swift
//  becap
//
//  Created by Adam Mabrouki on 04/09/2025.
//

import SwiftUI

// MARK: - Month Grid (single section, challenge-length)
struct CalendarMonthGrid: View {
    let startDate: Date
    let days: Int
    let selectedDate: Date?
    let photoCountByDay: [Date: Int]
    let onSelectDate: (Date) -> Void

    private let calendar = Calendar.current
    private let dayItems: [DayItem]
    private let leadingEmpty: Int
    private let trailingEmpty: Int

    init(startDate: Date,
         days: Int,
         selectedDate: Date?,
         photoCountByDay: [Date: Int],
         onSelectDate: @escaping (Date) -> Void) {
        self.startDate = startDate
        self.days = max(days, 0)
        self.selectedDate = selectedDate
        self.photoCountByDay = photoCountByDay
        self.onSelectDate = onSelectDate

        let calendar = Calendar.current
        let startOfChallenge = calendar.startOfDay(for: startDate)
        var items: [DayItem] = []
        items.reserveCapacity(self.days)

        for offset in 0..<self.days {
            if let date = calendar.date(byAdding: .day, value: offset, to: startOfChallenge) {
                items.append(DayItem(date: date, dayNumber: offset + 1))
            }
        }
        self.dayItems = items

        let firstWeekday = calendar.firstWeekday
        let startWeekday = calendar.component(.weekday, from: startOfChallenge)
        let leading = ((startWeekday - firstWeekday) + 7) % 7
        self.leadingEmpty = leading

        let totalCells = leading + items.count
        let remainder = totalCells % 7
        self.trailingEmpty = remainder == 0 ? 0 : (7 - remainder)
    }

    private let cellHeight: CGFloat = 54

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    header

                    WeekdayHeader()

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                        ForEach(0..<leadingEmpty, id: \.self) { index in
                            Color.clear.frame(height: cellHeight).id("leading-\(index)")
                        }

                        ForEach(dayItems) { item in
                            let day = calendar.startOfDay(for: item.date)
                            let count = photoCountByDay[day] ?? 0
                            let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false

                            DayCell(date: day,
                                    photoCount: count,
                                    isToday: calendar.isDateInToday(day),
                                    isWithinChallenge: true,
                                    isSelected: isSelected) {
                                onSelectDate(day)
                            }
                            .overlay(alignment: .bottom) {
                                Text("Jour \(item.dayNumber)")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.55))
                                    .padding(.bottom, 2)
                                    .allowsHitTesting(false)
                            }
                        }

                        ForEach(0..<trailingEmpty, id: \.self) { index in
                            Color.clear.frame(height: cellHeight).id("trailing-\(index)")
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.18), lineWidth: 0.7)
                )
            }
            .padding(.vertical, 6)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            if dayItems.isEmpty {
                Text("Aucun jour pour ce défi")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding(.leading, 6)
            } else {
                Text("Jour 1 à \(dayItems.count)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding(.leading, 6)

                if let first = dayItems.first?.date,
                   let last = dayItems.last?.date {
                    Text(intervalFormatter.string(from: first, to: last))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.65))
                        .padding(.leading, 6)
                }
            }
        }
    }

    private var intervalFormatter: DateIntervalFormatter {
        let formatter = DateIntervalFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    private struct DayItem: Identifiable {
        let date: Date
        let dayNumber: Int
        var id: Int { dayNumber }
    }
}
