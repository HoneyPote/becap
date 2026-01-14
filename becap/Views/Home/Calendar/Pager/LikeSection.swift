//
//  LikeSection.swift
//  becap
//
//  Created by Adam Mabrouki on 06/08/2025.
//

import SwiftUI

// TODO: Faire en sorte de ne rien calculer dans la vue. L'idéal est de ne pas avoir de vm juste pour cette section, voir pour utiliser vm de vue parent.
struct LikeSection: View {
    var postLikes: [String]
    let likeAction: (String) -> Void
    let unlikeAction: (String) -> Void
    let getParticipant: (String) -> ParticipantUIModel?

    var currentUserId: String? {
        UserManager.shared.currentUser?.id // Adapte si besoin
    }

    var alreadyLiked: Bool {
        guard let uid = currentUserId, !postLikes.isEmpty else { return false }
        return postLikes.contains(uid) ? true : false
    }

    var likeCount: Int {
        postLikes.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button(action: {
                    guard let uid = currentUserId else { return }
                    alreadyLiked ? unlikeAction(uid) : likeAction(uid)
                }) {
                    Image(systemName: alreadyLiked ? "heart.fill" : "heart")
                        .foregroundColor(alreadyLiked ? .red : .white)
                        .font(.system(size: 27, weight: .bold))
                        .shadow(radius: 2)
                }
                Text("\(likeCount) like\(likeCount > 1 ? "s" : "")")
                    .foregroundColor(.white.opacity(0.82))
                    .font(.subheadline.bold())
            }
            if !postLikes.isEmpty {
                let names = postLikes.compactMap { getParticipant($0)?.userName }
                if !names.isEmpty {
                    Text("Aimé par : \(names.joined(separator: ", "))")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.caption2)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 3)
    }
}
