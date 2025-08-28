//
//  CalendarCard.swift
//  becap
//
//  Created by Victor Derveaux on 17/08/2025.
//

import SwiftUI

struct CalendarCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.21), radius: 10, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.4), lineWidth: 0.7)
                )

            content
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
    }
}
