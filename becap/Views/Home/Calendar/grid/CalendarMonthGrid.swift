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
    let postCountByDay: [Date: Int]
    let attachmentCountByDay: [Date: Int]
    let jokerCountByDay: [Date: Int]
    let currentUserJokerDays: Set<Date>
    let onSelectDate: (Date) -> Void

    private let calendar = Calendar.current
    private let dayItems: [DayItem]
    private let leadingEmpty: Int
    private let trailingEmpty: Int

    init(startDate: Date,
         days: Int,
         selectedDate: Date?,
         postCountByDay: [Date: Int],
         attachmentCountByDay: [Date: Int],
         jokerCountByDay: [Date: Int],
         currentUserJokerDays: Set<Date>,
         onSelectDate: @escaping (Date) -> Void) {
        self.startDate = startDate
        self.days = max(days, 0)
        self.selectedDate = selectedDate
        self.postCountByDay = postCountByDay
        self.attachmentCountByDay = attachmentCountByDay
        self.jokerCountByDay = jokerCountByDay
        self.currentUserJokerDays = currentUserJokerDays
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

    private let cellHeight: CGFloat = 72

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    header

                    WeekdayHeader()

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 10) {
                        dayCells
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

    @ViewBuilder
    private var dayCells: some View {
        ForEach(0..<leadingEmpty, id: \.self) { index in
            Color.clear.frame(height: cellHeight).id("leading-\(index)")
        }

        ForEach(dayItems) { item in
            let day = calendar.startOfDay(for: item.date)
            var hasPosts: Bool { postCountByDay[day] ?? 0 > 0 }
            var hasAttachments: Bool { attachmentCountByDay[day] ?? 0 > 0 }
            var hasJokerUsage: Bool { jokerCountByDay[day] ?? 0 > 0 }

            let currentUserUsedJoker = currentUserJokerDays.contains(day)
            let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false

            DayCell(date: day,
                    dayNumber: item.dayNumber,
                    currentUserUsedJoker: currentUserUsedJoker,
                    isToday: calendar.isDateInToday(day),
                    isSelected: isSelected) {
                if hasPosts || hasJokerUsage {
                    Haptics.lightTap()
                }
                onSelectDate(day)
            }
                .overlay(alignment: .top) {
                    HStack(spacing: 3) {
                        if hasPosts {
                            HStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text("\(postCountByDay[day] ?? 0)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.25))
                            .clipShape(Capsule())
                        }

                        if hasAttachments {
                            Image(systemName: "paperclip")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.blue.opacity(0.25))
                                .clipShape(Circle())
                        }

                        if hasJokerUsage {
                            Circle()
                                .fill(jokerBadgeGradient)
                                .frame(width: 11, height: 11)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.85), lineWidth: 1)
                                )
                                .shadow(color: Color.purple.opacity(0.35), radius: 2, x: 0, y: 1)
                                .accessibilityLabel("Joker utilisé ce jour")
                                .accessibilityAddTraits(.isStaticText)
                        }
                    }
                    .padding(.top, -5)
                    .padding(.horizontal, -4)
                }

        }

        ForEach(0..<trailingEmpty, id: \.self) { index in
            Color.clear.frame(height: cellHeight).id("trailing-\(index)")
        }
    }

    private var jokerBadgeGradient: LinearGradient {
        LinearGradient(colors: [
            Color(red: 0.78, green: 0.47, blue: 0.98),
            Color(red: 0.61, green: 0.29, blue: 0.93)
        ], startPoint: .top, endPoint: .bottom)
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
        formatter.locale = Locale(identifier: "fr_FR")
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

