//
//  ReportShortcutCell.swift
//  becap
//
//  Created by OpenAI on 19/08/2025.
//

import SwiftUI

struct ReportShortcutCell: View {
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.33, green: 0.53, blue: 0.96))
                    .opacity(isDisabled ? 0.5 : 1)
                    .shadow(radius: 1, x: 0, y: 4)

                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.bubble")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 1, x: 0, y: 3)

                    Text("Signaler un défi")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
            }
            .frame(height: 100)
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
        .padding(4)
        .accessibilityLabel("Signaler un défi")
        .accessibilityHint(isDisabled ? "Rejoignez un défi pour pouvoir le signaler." : "Ouvre la fenêtre de signalement.")
    }
}

#Preview {
    ReportShortcutCell(isDisabled: false, onTap: {})
        .padding()
        .background(Color.black)
}
