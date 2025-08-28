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
                .background(Circle().fill(type == .success ? Color.green : Color.red).frame(width: 36, height: 36))

            Text(message)
                .foregroundColor(.white)
                .font(.headline)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .background(type == .success ? Color.green.opacity(0.92) : Color.red.opacity(0.92))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(.horizontal, 28)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: message)
    }
}
