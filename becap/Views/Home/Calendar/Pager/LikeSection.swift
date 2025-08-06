//
//  LikeSection.swift
//  becap
//
//  Created by Adam Mabrouki on 06/08/2025.
//
import SwiftUI

struct LikeSection: View {
    let photo: ChallengePhoto
    let challengeId: String
    let likeAction: (String) -> Void
    let unlikeAction: (String) -> Void
    let getParticipant: (String) -> Participant?

    var currentUserId: String? {
        UserManager.shared.currentUser?.id // Adapte si besoin
    }

    var alreadyLiked: Bool {
        guard let uid = currentUserId else { return false }
        return photo.likes?.contains(uid) ?? false
    }

    var likeCount: Int {
        photo.likes?.count ?? 0
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
            if let likes = photo.likes, !likes.isEmpty {
                let names = likes.compactMap { getParticipant($0)?.name }
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
