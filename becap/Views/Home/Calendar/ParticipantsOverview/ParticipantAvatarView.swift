//
//  ParticipantAvatarView.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//

import SwiftUI

struct ParticipantAvatarView: View {
    let name: String
    let photoURL: String?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.18))
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                )

            if let photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        ProgressView()
                    case .failure:
                        initialsView
                    @unknown default:
                        initialsView
                    }
                }
                .clipShape(Circle())
            } else {
                initialsView
            }
        }
        .frame(width: 64, height: 64)
    }

    private var initialsView: some View {
        Text(initials(from: name))
            .font(.system(.title2, design: .rounded).weight(.heavy))
            .foregroundColor(.white)
    }

    private func initials(from name: String) -> String {
        let components = name.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }
        return String(initials)
    }
}
