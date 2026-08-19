//
//  ShareButtonCell.swift
//  becap
//
//  Created by Adam Mabrouki on 18/07/2025.
//

import SwiftUI

struct ShareButtonCell: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: BecapMetrics.cardRadius, style: .continuous)
                    .fill(BecapColors.actionGradient)
                    .shadow(color: BecapColors.electricBlue.opacity(0.24), radius: 12, y: 7)
                VStack(spacing: 8) {
                    Image("network")
                           .resizable()
                           .scaledToFit()
                           .frame(width: 28, height: 28)
                           .foregroundColor(.white)
                           .shadow(radius: 1, x: 0, y: 3)

                    Text("Inviter des amis")
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
