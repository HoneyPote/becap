//
//  ToastView.swift
//  becap
//
//  Created by Adam Mabrouki on 31/07/2025.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type == .success ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundColor(.white)
                .imageScale(.large)
                .background(Circle().fill(type == .success ? BecapColors.mint : BecapColors.coral).frame(width: 36, height: 36))

            Text(message)
                .foregroundColor(.white)
                .font(BecapTypography.headline)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .background(type == .success ? BecapColors.mint.opacity(0.94) : BecapColors.coral.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: BecapMetrics.controlRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BecapMetrics.controlRadius, style: .continuous)
                .stroke(BecapColors.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.20), radius: 12, y: 6)
        .padding(.horizontal, 28)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: message)
    }
}
