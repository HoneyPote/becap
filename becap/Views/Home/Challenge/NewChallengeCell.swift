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
                RoundedRectangle(cornerRadius: BecapMetrics.cardRadius, style: .continuous)
                    .fill(BecapColors.coral)
                    .shadow(color: BecapColors.coral.opacity(0.22), radius: 12, y: 7)

                VStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 1, x: 0, y: 3)

                    Text("Créer un défi")
                        .font(BecapTypography.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
            }
            .frame(height: 100)
            .contentShape(RoundedRectangle(cornerRadius: BecapMetrics.cardRadius))

        }
        .buttonStyle(PlainButtonStyle())
        .padding(4)
    }
}
