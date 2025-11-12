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

/// Video caching testing

//import Foundation
//import AVFoundation
//import AVKit
//
//final class VideoCache {
//    static let shared = VideoCache()
//    private init() {}
//
//    private let fileManager = FileManager.default
//    private let cacheDirectory: URL = {
//        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
//        let dir = urls[0].appendingPathComponent("VideoCache")
//        if !FileManager.default.fileExists(atPath: dir.path) {
//            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
//        }
//        return dir
//    }()
//
//    /// Récupère un fichier vidéo local si déjà téléchargé
//    func getVideo(forKey key: String) -> URL? {
//        let fileURL = cacheDirectory.appendingPathComponent(key)
//        let returnedValue = fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
//        print("GET VIDEO RETURN : ", returnedValue)
//        return returnedValue
//    }
//
//    /// Télécharge et met en cache la vidéo
//    func downloadVideo(from remoteURL: URL, completion: @escaping (URL?) -> Void) {
//        let key = remoteURL.lastPathComponent
//        let localURL = cacheDirectory.appendingPathComponent(key)
//
//        if fileManager.fileExists(atPath: localURL.path) {
//            completion(localURL)
//            return
//        }
//
//        URLSession.shared.downloadTask(with: remoteURL) { tempURL, _, error in
//            guard let tempURL = tempURL, error == nil else {
//                print("FAILED TO DOWNLOAD VIDEO FROM \(remoteURL)")
//                completion(nil)
//                return
//            }
//
//            do {
//                try self.fileManager.moveItem(at: tempURL, to: localURL)
//                completion(localURL)
//            } catch {
//                print("❌ Erreur lors de la mise en cache :", error)
//                completion(nil)
//            }
//        }.resume()
//    }
//
//    /// Supprime un fichier du cache
//    func delete(forKey key: String) {
//        let fileURL = cacheDirectory.appendingPathComponent(key)
//        try? fileManager.removeItem(at: fileURL)
//    }
//
//    /// Vide tout le cache
//    func clearCache() {
//        try? fileManager.removeItem(at: cacheDirectory)
//        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
//    }
//}
//
//struct AsyncCachedVideo: View {
//    @State private var isDoneLoading: Bool = false
//    let url: URL
//
//    var body: some View {
//        Group {
//            if isDoneLoading {
//                CustomVideoPlayer(videoURL: url)
//            } else {
//                ProgressView()
//                    .onAppear { loadVideo() }
//            }
//        }
//    }
//
//    private func loadVideo() {
//        print("START LOADING URL : ", url)
//        if let cachedURL = VideoCache.shared.getVideo(forKey: url.lastPathComponent) {
//            self.isDoneLoading = true
//            print("DONE LOADING URL")
//        } else {
//            VideoCache.shared.downloadVideo(from: url) { localURL in
//                DispatchQueue.main.async {
//                    if let localURL = localURL {
//                        self.isDoneLoading = true
//                        print("DONE LOADING")
//                    }
//                }
//            }
//        }
//    }
//}
