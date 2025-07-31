
// JoinButtonCell.swift
// becap

import SwiftUI

struct JoinButtonCell: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.5, green: 0.0, blue: 0.1),   // bordeaux
                                Color(red: 0.7, green: 0.3, blue: 0.3)    // vieux rose
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 20, x: 5, y: 5)

                VStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)

                    Text("Nouveau Challenge")
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
        .buttonStyle(PlainButtonStyle())
        .padding(4)
    }
}
