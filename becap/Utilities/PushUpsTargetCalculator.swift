//
//  PushUpsTargetCalculator.swift
//  becap
//
//  Created by OpenAI on 2025-11-01.
//

import Foundation

struct PushUpsTargetCalculator {
    static let baseTarget = 20
    static let rampDays = 10

    static func dayIndex(for date: Date,
                         startDate: Date,
                         calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: startDate)
        let current = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: current).day ?? 0
        return max(days + 1, 1)
    }

    static func dailyTarget(dayIndex: Int) -> Int {
        let day = max(dayIndex, 1)
        if day <= rampDays {
            return baseTarget + (day - 1) * 2
        }

        let rampTarget = baseTarget + (rampDays - 1) * 2
        return rampTarget + (day - rampDays)
    }

    static func dailyTarget(on date: Date,
                            startDate: Date,
                            calendar: Calendar = .current) -> Int {
        dailyTarget(dayIndex: dayIndex(for: date, startDate: startDate, calendar: calendar))
    }
}
