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
    let isEditingPremiumContent: Bool
    let onSelectDate: (Date) -> Void
    let onAddAttachmentForDay: (Int) -> Void

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
         isEditingPremiumContent: Bool,
         onSelectDate: @escaping (Date) -> Void,
         onAddAttachmentForDay: @escaping (Int) -> Void) {
        self.startDate = startDate
        self.days = max(days, 0)
        self.selectedDate = selectedDate
        self.postCountByDay = postCountByDay
        self.attachmentCountByDay = attachmentCountByDay
        self.jokerCountByDay = jokerCountByDay
        self.currentUserJokerDays = currentUserJokerDays
        self.isEditingPremiumContent = isEditingPremiumContent
        self.onSelectDate = onSelectDate
        self.onAddAttachmentForDay = onAddAttachmentForDay

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
    private let compactCellHeight: CGFloat = 60

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if let selectedDate {
                    compactWeekView(for: selectedDate)
                } else {
                    fullMonthView
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var fullMonthView: some View {
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

    private func compactWeekView(for selectedDate: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            compactHeader(for: selectedDate)

            WeekdayHeader()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 10) {
                compactDayCells(for: selectedDate)
            }
            .padding(.horizontal, 2)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
        )
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
                if hasPosts || hasJokerUsage || hasAttachments {
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
                .overlay(alignment: .bottomTrailing) {
                    if isEditingPremiumContent {
                        Button {
                            onAddAttachmentForDay(item.dayNumber)
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 28, height: 28)
                                .background(
                                    LinearGradient(colors: [
                                        Color.white,
                                        Color.white.opacity(0.92)
                                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                        }
//                        .buttonStyle(.hapticPlain)
                        .padding(6)
                    }
                }

        }

        ForEach(0..<trailingEmpty, id: \.self) { index in
            Color.clear.frame(height: cellHeight).id("trailing-\(index)")
        }
    }

    @ViewBuilder
    private func compactDayCells(for selectedDate: Date) -> some View {
        let weekDates = weekDates(for: selectedDate)

        ForEach(weekDates.indices, id: \.self) { index in
            if let item = weekDates[index] {
                let day = calendar.startOfDay(for: item.date)
                var hasPosts: Bool { postCountByDay[day] ?? 0 > 0 }
                var hasAttachments: Bool { attachmentCountByDay[day] ?? 0 > 0 }
                var hasJokerUsage: Bool { jokerCountByDay[day] ?? 0 > 0 }

                let currentUserUsedJoker = currentUserJokerDays.contains(day)
                let isSelected = calendar.isDate(selectedDate, inSameDayAs: day)

                DayCell(date: day,
                        dayNumber: item.dayNumber,
                        currentUserUsedJoker: currentUserUsedJoker,
                        isToday: calendar.isDateInToday(day),
                        isSelected: isSelected) {
                    if hasPosts || hasJokerUsage || hasAttachments {
                        Haptics.lightTap()
                    }
                    onSelectDate(day)
                }
                .frame(height: compactCellHeight)
            } else {
                CompactDayPlaceholder()
                    .frame(height: compactCellHeight)
            }
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

    private func compactHeader(for selectedDate: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selectedDate, style: .date)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .padding(.leading, 6)

            Text("Semaine sélectionnée")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.65))
                .padding(.leading, 6)
        }
    }

    private func weekDates(for selectedDate: Date) -> [DayItem?] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return Array(repeating: nil, count: 7)
        }

        let startOfChallenge = calendar.startOfDay(for: startDate)
        let endOfChallenge = calendar.date(byAdding: .day, value: days - 1, to: startOfChallenge)

        return (0..<7).map { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekInterval.start) else { return nil }
            guard let endDate = endOfChallenge else { return nil }
            guard date >= startOfChallenge && date <= endDate else { return nil }
            let dayNumber = calendar.dateComponents([.day], from: startOfChallenge, to: date).day ?? 0
            return DayItem(date: date, dayNumber: dayNumber + 1)
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

private struct CompactDayPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
            )
    }
}
