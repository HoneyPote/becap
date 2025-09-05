//
//  AsyncPhotoPagerView.swift
//  becap
//
//  Created by Adam Mabrouki on 06/08/2025.
//

import SwiftUI

final class ImageCache {
    static let shared = ImageCache()
    private init() {}

    private let cache = NSCache<NSString, UIImage>()

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

struct AsyncCachedImage: View {
    let url: URL

    @State private var uiImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .cornerRadius(18)
                    .shadow(radius: 18)
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Color.gray.opacity(0.3)
                    .overlay {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                    .onAppear { loadImage() }
            }
        }
    }

    private func loadImage() {
        guard !isLoading else { return }
        if let cached = ImageCache.shared.image(forKey: url.absoluteString) {
            self.uiImage = cached
            return
        }

        isLoading = true
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { isLoading = false }
            if let data = data, let img = UIImage(data: data) {
                ImageCache.shared.insert(img, forKey: url.absoluteString)
                DispatchQueue.main.async {
                    self.uiImage = img
                }
            }
        }.resume()
    }
}
