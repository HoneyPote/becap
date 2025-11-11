//
//  NewChallengeCell.swift
//  becap
//
//  Created by Adam Mabrouki on 03/08/2025.
//

import SwiftUI

struct NewChallengeCell: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 1.0, green: 0.71, blue: 0.81))
                    .shadow(radius: 1, x: 0, y: 4)
                    .opacity(0.95)

                VStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 1, x: 0, y: 3)

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
