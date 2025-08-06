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
                            .scaledToFit()
                            .cornerRadius(18)
                            .shadow(radius: 18)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    case .empty:
                        ProgressView()
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

