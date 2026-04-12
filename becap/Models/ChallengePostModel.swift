//
//  ChallengePostModel.swift
//  becap
//
//  Created by Victor Derveaux on 09/02/2026.
//

import FirebaseFirestore
import Foundation

struct ChallengePost: Identifiable, Codable, Hashable {
    @DocumentID private var _id: String?
    var id: String {
        _id ?? ""
    }
    var challengeId: String              // ID du défi (parent)
    var authorUid: String                // UID Firebase de l'auteur
    var authorName: String               // Nom ou prénom affiché
    var description: String?             // Description optionnelle (légende)
    var date: Date                       // Date de prise ou de soumission

    var likes: [String]?
    var jokerState: PostJokerState?

    var media: ChallengeMedia

    init(challengeId: String,
         authorUid: String,
         authorName: String,
         description: String?,
         date: Date,
         likes: [String]? = nil,
         jokerState: PostJokerState? = nil,
         media: ChallengeMedia) {
        self.challengeId = challengeId
        self.authorUid = authorUid
        self.authorName = authorName
        self.description = description
        self.date = date
        self.likes = likes
        self.jokerState = jokerState
        self.media = media
    }

    static func == (lhs: ChallengePost, rhs: ChallengePost) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum ChallengeRawMedia: Equatable {
    case image(UIImage)
    case video(VideoRawData)

    struct VideoRawData: Equatable {
        var url: URL
        var thumbnailImage: UIImage?
    }
}

enum ChallengeMedia: Codable, Hashable {
    case image(url: String)
    case video(VideoData)

    struct VideoData: Codable, Hashable {
        var videoURL: String
        var thumbnailURL: String?
    }

    enum CodingKeys: String, CodingKey {
        case type
        case imageURL
        case video
    }

    enum MediaType: String, Codable {
        case image
        case video
    }

    // MARK: - Codable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MediaType.self, forKey: .type)

        switch type {
        case .image:
            let imageURL = try container.decode(String.self, forKey: .imageURL)
            self = .image(url: imageURL)
        case .video:
            let videoData = try container.decode(VideoData.self, forKey: .video)
            self = .video(videoData)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .image(let url):
            try container.encode(MediaType.image, forKey: .type)
            try container.encode(url, forKey: .imageURL)
        case .video(let videoData):
            try container.encode(MediaType.video, forKey: .type)
            try container.encode(videoData, forKey: .video)
        }
    }

    // MARK: - Helpers

    var thumbnailImageUrl: String? {
        switch self {
        case .image(let url):
            return url
        case .video(let data):
            return data.thumbnailURL
        }
    }
}

