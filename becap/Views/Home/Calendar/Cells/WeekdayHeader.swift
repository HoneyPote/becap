//
//  WeekdayHeader.swift
//  becap
//
//  Created by Adam Mabrouki on 04/09/2025.
//
import SwiftUI

// MARK: - Weekday header + Day cell
 struct WeekdayHeader: View {
    private let cal = Calendar.current
    private var symbols: [String] {
        var symbols = cal.shortWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first]).map {
            String($0.prefix(2)).uppercased()
        }
    }

    var body: some View {
        HStack {
            ForEach(symbols, id: \.self) { s in
                Text(s)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
    }
}
