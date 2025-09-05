//
//  CalendarMonthGrid.swift
//  becap
//
//  Created by Adam Mabrouki on 04/09/2025.
//

import SwiftUI

// MARK: - Day helpers (normalize to day precision everywhere)
private let CAL = Calendar.current
private func startOfDay(_ d: Date) -> Date { CAL.startOfDay(for: d) }
private func sameDay(_ a: Date, _ b: Date) -> Bool { CAL.isDate(a, equalTo: b, toGranularity: .day) }

// TODO: Voir pour travailler avec VM + découper vue
// MARK: - Month Grid (Apple-like, cached months)
struct CalendarMonthGrid: View {
    let startDate: Date
    let days: Int
    let selectedDate: Date?
    let photoCountByDay: [Date: Int]
    let onSelectDate: (Date) -> Void
    
    private let cal = Calendar.current
    private let months: [MonthBlock]   // cached at init
    
    init(startDate: Date,
         days: Int,
         selectedDate: Date?,
         photoCountByDay: [Date: Int],
         onSelectDate: @escaping (Date) -> Void) {
        self.startDate = startDate
        self.days = days
        self.selectedDate = selectedDate
        self.photoCountByDay = photoCountByDay
        self.onSelectDate = onSelectDate
        self.months = CalendarMonthGrid.buildMonthsStatic(startDate: startDate, days: days)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(months, id: \.self.startOfMonth) { month in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(month.title)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                            .padding(.leading, 6)
                        
                        WeekdayHeader()
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                            ForEach(0..<month.leadingEmpty, id: \.self) { _ in
                                Color.clear.frame(height: 42)
                            }
                            
                            ForEach(0..<month.dayCount, id: \.self) { i in
                                let date = cal.date(byAdding: .day, value: i, to: month.startOfMonth)!
                                let day = startOfDay(date)
                                let count = photoCountByDay[day] ?? 0
                                let isSel = selectedDate.map { sameDay($0, day) } ?? false
                                
                                DayCell(
                                    date: day,
                                    photoCount: count,
                                    isToday: cal.isDateInToday(day),
                                    isWithinChallenge: month.validDays.contains(day),
                                    isSelected: isSel
                                ) {
                                    onSelectDate(day)
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.18), lineWidth: 0.7)
                    )
                }
            }
            .padding(.vertical, 6)
        }
    }
    
    // Build month blocks once (static)
    private static func buildMonthsStatic(startDate: Date, days: Int) -> [MonthBlock] {
        let cal = Calendar.current
        let sDay = cal.startOfDay(for: startDate)
        let endDate = cal.date(byAdding: .day, value: max(0, days - 1), to: sDay)!
        var blocks: [MonthBlock] = []
        
        var cursor = cal.date(from: cal.dateComponents([.year, .month], from: sDay))!
        let endCursor = cal.date(from: cal.dateComponents([.year, .month], from: endDate))!
        
        while cursor <= endCursor {
            let startOfThisMonth = cursor
            let dayCount = cal.range(of: .day, in: .month, for: startOfThisMonth)?.count ?? 30
            
            let weekday = cal.component(.weekday, from: startOfThisMonth)
            let firstWeekday = cal.firstWeekday
            let leading = ((weekday - firstWeekday) + 7) % 7
            
            var valid: [Date] = []
            valid.reserveCapacity(dayCount)
            for d in 0..<dayCount {
                let date = cal.date(byAdding: .day, value: d, to: startOfThisMonth)!
                let day = cal.startOfDay(for: date)
                if day >= sDay && day <= endDate { valid.append(day) }
            }
            
            let df = DateFormatter()
            df.locale = .current
            df.setLocalizedDateFormatFromTemplate("MMMM yyyy")
            let title = df.string(from: startOfThisMonth).capitalized
            
            blocks.append(MonthBlock(
                startOfMonth: startOfThisMonth,
                title: title,
                dayCount: dayCount,
                leadingEmpty: leading,
                validDays: valid
            ))
            cursor = cal.date(byAdding: .month, value: 1, to: startOfThisMonth)!
        }
        return blocks
    }
    
    private struct MonthBlock: Hashable {
        let startOfMonth: Date
        let title: String
        let dayCount: Int
        let leadingEmpty: Int
        let validDays: [Date]
    }
}

