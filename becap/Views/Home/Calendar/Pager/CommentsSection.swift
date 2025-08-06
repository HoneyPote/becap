//
//  CommentsSection.swift
//  becap
//
//  Created by Adam Mabrouki on 06/08/2025.
//

import SwiftUI

struct CommentsSection: View {
    @Binding var comments: [PhotoCommentModel]
    @FocusState.Binding var isTextFieldFocused: Bool
    var onSubmit: (String) -> Void

    @State private var commentText = ""


    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(comments) { comment in
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.userName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text(comment.content)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.bottom, 4)
            }

            Divider().background(Color.white.opacity(0.25))

            HStack {
                TextField("Ajouter un commentaire...", text: $commentText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        send()
                    }

                Button(action: send) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .onTapGesture {
            isTextFieldFocused = false // ferme le clavier quand on tape autour
        }
    }

    private func send() {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
        commentText = ""
    }
}

