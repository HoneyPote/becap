//
//  ToastView.swift
//  becap
//
//  Created by Adam Mabrouki on 31/07/2025.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.white)
                .imageScale(.large)

            Text(message)
                .foregroundColor(.white)
                .font(.headline)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .background(.black.opacity(0.7))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(.horizontal, 24)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
