//
//  WeekdayHeader.swift
//  becap
//
//  Created by Adam Mabrouki on 04/09/2025.
//

import SwiftUI

struct WeekdayHeader: View {
    private var symbols: [String] {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "fr_FR")
        let symbols = calendar.shortWeekdaySymbols
        let first = calendar.firstWeekday - 1

        return Array(symbols[first...] + symbols[..<first]).map {
            String($0.prefix(2)).uppercased()
        }
    }

    var body: some View {
        HStack {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
    }
}
