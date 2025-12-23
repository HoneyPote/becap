//
//  GridPostsInline.swift
//  becap
//
//  Created by Adam Mabrouki on 04/09/2025.
//

import SwiftUI
import AVFoundation
import AVKit
import QuickLook
import UniformTypeIdentifiers

// TODO: Découper vue
struct GridPostsInline: View {
    let cell: CalendarDetailCell
    let getParticipant: (String) -> Participant?
    let onClose: () -> Void
    let onOpenPager: (PagerInfo) -> Void

    @State private var quickLookURL: URL?
    @State private var videoURL: URL?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    private let jokerColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
    private let mediaColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)

    private var postsSorted: [ChallengePost] {
        cell.posts.sorted {
            guard $0.authorName != $1.authorName else { return $0.date > $1.date }

            return $0.authorName.localizedCaseInsensitiveCompare($1.authorName) == .orderedAscending
        }
    }

    private func thumbnailUrl(media: ChallengeMedia) -> URL? {
        guard let thumbnailUrl = media.thumbnailImageUrl, let url = URL(string: thumbnailUrl) else { return nil }

        return url
    }
    private var influencerMediaAttachments: [PremiumCalendarAttachment] {
        cell.premiumAttachments.filter { $0.kind == .media }
    }

    private var documentAttachments: [PremiumCalendarAttachment] {
        cell.premiumAttachments.filter { $0.kind == .pdf }
    }

    private var hasPosts: Bool { !cell.posts.isEmpty }
    private var hasInfluencerMedia: Bool { !influencerMediaAttachments.isEmpty }
    private var hasDocuments: Bool { !documentAttachments.isEmpty }
    private var hasJokers: Bool { !cell.jokers.isEmpty }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(cell.date, style: .date)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.25))
                        .clipShape(Circle())
                }
            }

            ScrollView {
                VStack {
                    if let videoURL {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .frame(height: 220)
                            .cornerRadius(12)
                            .padding(.bottom, 4)
                    }

                    if let quickLookURL {
                        QuickLookPreview(url: quickLookURL)
                            .frame(height: 320)
                            .cornerRadius(12)
                            .padding(.bottom, 4)
                            .background(Color.white.opacity(0.08))
                    }

                    if hasInfluencerMedia {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Sélection de l'influenceur ✨")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundColor(.white)

                            Text("Touchez un média pour l'afficher en grand.")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))

                            LazyVGrid(columns: mediaColumns, spacing: 8) {
                                ForEach(influencerMediaAttachments) { attachment in
                                    InfluencerMediaTile(attachment: attachment,
                                                        previewKind: previewKind(for: attachment),
                                                        onOpen: { open(attachment: attachment) })
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if postsSorted.isEmpty {
                        Text("Aucun post partagé ce jour.")
                            .font(.system(.callout, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .padding([.bottom, .top], 30)
                    } else {
                        VStack(alignment: .leading) {
                            Text("Posts du jour 📸")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundColor(.white)

                            LazyVGrid(columns: columns, spacing: 8) {
                                postsView
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if hasDocuments {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Documents premium 📎")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundColor(.white)

                            ForEach(documentAttachments) { attachment in
                                Button {
                                    open(attachment: attachment)
                                } label: {
                                    PremiumAttachmentRow(attachment: attachment)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if hasJokers {
                        VStack(alignment: .leading) {
                            Text("Jokers utilisés 🟣")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundColor(.white)

                            LazyVGrid(columns: jokerColumns, spacing: 8) {
                                ForEach(cell.jokers) { usage in
                                    JokerUsageRow(usage: usage)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxHeight: 420)
        }
    }

    private var postsView: some View {
        ForEach(Array(postsSorted.enumerated()), id: \.offset) { (idx, post) in
            // TODO: Bouton certainement pas nécessaire, VSTack avec onTapAction() plutôt
            Button {
                onOpenPager(PagerInfo(posts: postsSorted, index: idx, date: post.date))
            } label: {
                VStack(spacing: 2) {
                    if let thumbnailImageUrl = thumbnailUrl(media: post.media) {
                        AsyncCachedImage(url: thumbnailImageUrl)
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(8)
                    }

                    HStack(spacing: 4) {
                        Text(post.authorName)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if let participant = getParticipant(post.authorUid),
                           let latest = participant.medals.sorted(by: { $0.achievedDate > $1.achievedDate }).first {
                            MedalIconView(iconName: latest.iconName)
                                .frame(width: 20, height: 20)
                                .shadow(color: Color.black.opacity(0.13), radius: 2, x: 0, y: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func open(attachment: PremiumCalendarAttachment) {
        Task { await openAsync(attachment: attachment) }
    }

    @MainActor
    private func openAsync(attachment: PremiumCalendarAttachment) async {
        // 1) si le fichier existe localement -> ok
        if let local = attachment.localFileURL, FileManager.default.fileExists(atPath: local.path) {
            present(localURL: local, kind: attachment.kind, previewKind: previewKind(for: attachment))
            return
        }

        // 2) sinon, si remoteURL existe -> download + cache -> open
        guard let remote = attachment.remoteURL else { return }

        do {
            let cachedURL = try await PremiumAttachmentCache.shared.downloadIfNeeded(remoteURL: remote,
                                                                                   suggestedFileName: attachment.fileName)
            present(localURL: cachedURL, kind: attachment.kind, previewKind: previewKind(for: cachedURL))
        } catch {
            print("❌ download attachment failed: \(error)")
        }
    }

    @MainActor
    private func present(localURL: URL, kind: PremiumAttachmentKind, previewKind: AttachmentPreviewKind) {
        switch kind {
        case .pdf:
            videoURL = nil
            quickLookURL = localURL
        case .media:
            quickLookURL = nil
            if previewKind == .video {
                videoURL = localURL
            } else {
                videoURL = nil
                quickLookURL = localURL
            }
        }
    }

    private func previewKind(for attachment: PremiumCalendarAttachment) -> AttachmentPreviewKind {
        guard attachment.kind == .media, let url = attachment.localFileURL else { return .unknown }

        return previewKind(for: url)
    }

    private func previewKind(for url: URL) -> AttachmentPreviewKind {
        let ext = url.pathExtension
        guard let type = UTType(filenameExtension: ext) else { return .unknown }

        if type.conforms(to: .movie) {
            return .video
        }

        if type.conforms(to: .image) {
            return .image
        }

        return .unknown
    }
}

private enum AttachmentPreviewKind {
    case image
    case video
    case unknown
}

private struct InfluencerMediaTile: View {
    let attachment: PremiumCalendarAttachment
    let previewKind: AttachmentPreviewKind
    let onOpen: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: onOpen) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.08))

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: previewKind == .video ? "play.circle.fill" : "photo.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))

                        Text(attachment.title)
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Text(attachment.title)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Capsule())
                    .padding(8)

                if previewKind == .video {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
        .onAppear { loadThumbnailIfNeeded() }
    }

    private func loadThumbnailIfNeeded() {
        guard thumbnail == nil, let url = attachment.localFileURL else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            let image: UIImage?
            switch previewKind {
            case .image:
                image = UIImage(contentsOfFile: url.path)
            case .video:
                image = generateVideoThumbnail(url: url)
            case .unknown:
                image = nil
            }

            guard let image else { return }
            DispatchQueue.main.async {
                thumbnail = image
            }
        }
    }

    private func generateVideoThumbnail(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.2, preferredTimescale: 600)
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

private struct JokerUsageRow: View {
    let usage: CalendarDayJokerUsage

    private var subtitle: String {
        if usage.declaredByAuthor {
            return "Auto-déclaré par le participant"
        }

        if usage.voteCount == 0 {
            return "Validé par la communauté"
        }

        let names = usage.voterNames
        if names.isEmpty {
            return "Validé par \(usage.voteCount) vote(s)"
        }

        return "Validé par : " + names.joined(separator: ", ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            JokerIconView(size: 30, isDimmed: false)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(usage.participantName)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct PremiumAttachmentRow: View {
    let attachment: PremiumCalendarAttachment

    private var iconName: String {
        switch attachment.kind {
        case .media: return "play.rectangle.fill"
        case .pdf: return "doc.richtext.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.white, Color.white.opacity(0.7))
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(attachment.title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)

                Text(attachment.kind == .pdf ? "Document PDF" : "Média premium")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            if let url = attachment.localFileURL {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}

import Foundation

final class PremiumAttachmentCache {
    static let shared = PremiumAttachmentCache()
    private init() {}

    func downloadIfNeeded(remoteURL: String, suggestedFileName: String) async throws -> URL {
        guard let url = URL(string: remoteURL) else { throw URLError(.badURL) }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destination = docs.appendingPathComponent(suggestedFileName)

        // déjà en cache ?
        if FileManager.default.fileExists(atPath: destination.path) {
            return destination
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        try data.write(to: destination, options: .atomic)
        return destination
    }
}
