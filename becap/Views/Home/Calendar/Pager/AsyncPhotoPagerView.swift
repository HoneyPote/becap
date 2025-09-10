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

    func getImage(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    func delete(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
}

struct AsyncCachedImage: View {
    @State private var uiImage: UIImage?
    @State private var isLoading = false

    let url: URL

    private let imageCache: ImageCache

    init(url: URL, imageCache: ImageCache = ImageCache.shared) {
        self.url = url
        self.imageCache = imageCache
    }

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

        if let cached = imageCache.getImage(forKey: url.absoluteString) {
            self.uiImage = cached
            return
        }

        isLoading = true
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { isLoading = false }

            if let data, let image = UIImage(data: data) {
                imageCache.insert(image, forKey: url.absoluteString)

                DispatchQueue.main.async {
                    self.uiImage = image
                }
            }
        }.resume()
    }
}
