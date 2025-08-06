//
//  AsyncPhotoPagerView.swift
//  becap
//
//  Created by Adam Mabrouki on 06/08/2025.
//

import SwiftUI

 struct AsyncPhotoPagerView: View {
    let photo: ChallengePhoto

    var body: some View {
        Group {
            if let url = URL(string: photo.imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                            .cornerRadius(18)
                            .shadow(radius: 18)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    case .empty:
                        ZStack {
                            Color.black.opacity(0.2)
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }
        }
    }
}

