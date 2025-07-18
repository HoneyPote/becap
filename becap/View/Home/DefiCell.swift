//
//  DefiCell.swift
//  becap
//
//  Created by Adam Mabrouki on 16/07/2025.
//
import SwiftUI

struct DefiCell: View {
    let defi: Defi
    let deleteAction: () -> Void

    var body: some View {
        NavigationLink(destination: CalendarDetailView(defi: defi)) {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(height: 100)
                .overlay(Text(defi.name))
                .cornerRadius(12)
        }
        .contextMenu {
            Button(role: .destructive, action: deleteAction) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
