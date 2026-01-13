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

struct GridPostsInline: View {
    let cell: CalendarDetailCell
    let getParticipant: (String) -> Participant?
    let onClose: () -> Void
    let onOpenPager: (PagerInfo) -> Void

    @State private var quickLookURL: URL?
    @State private var videoURL: URL?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: InlineStyle.gridSpacing), count: 3)
    private let jokerColumns = Array(repeating: GridItem(.flexible(), spacing: InlineStyle.gridSpacing), count: 2)

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
        VStack(spacing: InlineStyle.outerSpacing) {
            InlineHeader(date: cell.date, onClose: onClose)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: InlineStyle.sectionSpacing, pinnedViews: [.sectionHeaders]) {
                    if let videoURL {
                        PreviewCard(title: "Aperçu vidéo", subtitle: "Touchez pour agrandir", accent: InlineStyle.accent) {
                            VideoPlayer(player: AVPlayer(url: videoURL))
                                .frame(height: InlineStyle.previewHeight)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if let quickLookURL {
                        PreviewCard(title: "Aperçu document", subtitle: "Quick Look", accent: InlineStyle.accent) {
                            QuickLookPreview(url: quickLookURL)
                                .frame(height: InlineStyle.previewHeight + 80)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if hasInfluencerMedia {
                        Section {
                            InfluencerCarousel(attachments: influencerMediaAttachments,
                                               previewKind: { previewKind(for: $0) },
                                               onOpen: { open(attachment: $0) })
                        } header: {
                            SectionHeader(title: "Sélection de l'influenceur", subtitle: "Highlights du jour", symbol: "sparkles")
                        }
                    } else {
                        Section {
                            EmptyStateView(text: "Aucun média de l'influenceur aujourd'hui.")
                        } header: {
                            SectionHeader(title: "Sélection de l'influenceur", subtitle: "Highlights du jour", symbol: "sparkles")
                        }
                    }

                    Section {
                        if hasPosts {
                            LazyVGrid(columns: columns, spacing: InlineStyle.gridSpacing) {
                                postsView
                            }
                        } else {
                            EmptyStateView(text: "Aucun post partagé ce jour.")
                        }
                    } header: {
                        SectionHeader(title: "Posts du jour", subtitle: "Vos participants", symbol: "photo.on.rectangle.angled")
                    }

                    if hasDocuments {
                        Section {
                            VStack(spacing: InlineStyle.gridSpacing) {
                                ForEach(documentAttachments) { attachment in
                                    Button {
                                        open(attachment: attachment)
                                    } label: {
                                        AttachmentRow(attachment: attachment)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } header: {
                            SectionHeader(title: "Documents premium", subtitle: "PDF & guides", symbol: "doc.richtext")
                        }
                    } else {
                        Section {
                            EmptyStateView(text: "Aucun document premium pour cette journée.")
                        } header: {
                            SectionHeader(title: "Documents premium", subtitle: "PDF & guides", symbol: "doc.richtext")
                        }
                    }

                    if hasJokers {
                        Section {
                            LazyVGrid(columns: jokerColumns, spacing: InlineStyle.gridSpacing) {
                                ForEach(cell.jokers) { usage in
                                    JokerRow(usage: usage)
                                }
                            }
                        } header: {
                            SectionHeader(title: "Jokers utilisés", subtitle: "Votes & validations", symbol: "circle.hexagonpath")
                        }
                    } else {
                        Section {
                            EmptyStateView(text: "Aucun joker utilisé aujourd'hui.")
                        } header: {
                            SectionHeader(title: "Jokers utilisés", subtitle: "Votes & validations", symbol: "circle.hexagonpath")
                        }
                    }
                }
                .padding(.horizontal, InlineStyle.horizontalPadding)
                .padding(.bottom, InlineStyle.bottomPadding)
            }
            .frame(maxHeight: InlineStyle.maxHeight)
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: videoURL)
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: quickLookURL)
        }
        .padding(.top, InlineStyle.topPadding)
        .background(
            RoundedRectangle(cornerRadius: InlineStyle.containerRadius, style: .continuous)
                .fill(InlineStyle.containerFill)
                .overlay(
                    RoundedRectangle(cornerRadius: InlineStyle.containerRadius, style: .continuous)
                        .stroke(Color.white.opacity(InlineStyle.containerStrokeOpacity), lineWidth: 0.8)
                )
        )
        .padding(.horizontal, InlineStyle.containerInset)
    }

    private var postsView: some View {
        ForEach(Array(postsSorted.enumerated()), id: \.offset) { (idx, post) in
            Button {
                onOpenPager(PagerInfo(posts: postsSorted, index: idx, date: post.date))
            } label: {
                PostTile(post: post,
                         thumbnailURL: thumbnailUrl(media: post.media),
                         medalIconName: latestMedalIconName(for: post))
            }
            .buttonStyle(.plain)
        }
    }

    private func latestMedalIconName(for post: ChallengePost) -> String? {
        guard let participant = getParticipant(post.authorUid) else { return nil }

        return participant.medals.sorted(by: { $0.achievedDate > $1.achievedDate }).first?.iconName
    }

    private func open(attachment: PremiumCalendarAttachment) {
        Task { await openAsync(attachment: attachment) }
    }

    @MainActor
    private func openAsync(attachment: PremiumCalendarAttachment) async {
        if let local = attachment.localFileURL, FileManager.default.fileExists(atPath: local.path) {
            present(localURL: local, kind: attachment.kind, previewKind: previewKind(for: attachment))
            return
        }

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
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
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

private enum InlineStyle {
    static let outerSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 20
    static let gridSpacing: CGFloat = 10
    static let horizontalPadding: CGFloat = 16
    static let bottomPadding: CGFloat = 24
    static let topPadding: CGFloat = 8
    static let containerInset: CGFloat = 12
    static let containerRadius: CGFloat = 26
    static let cardRadius: CGFloat = 18
    static let smallRadius: CGFloat = 12
    static let previewHeight: CGFloat = 220
    static let maxHeight: CGFloat = 460
    static let containerStrokeOpacity: Double = 0.2
    static let containerFill: some ShapeStyle = .ultraThinMaterial
    static let accent = Color(red: 0.55, green: 0.83, blue: 0.96)
    static let secondaryTextOpacity: Double = 0.72
    static let captionOpacity: Double = 0.58
}

private enum AttachmentPreviewKind {
    case image
    case video
    case unknown
}

private struct InlineHeader: View {
    let date: Date
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(date, style: .date)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.white)

                Text(date, style: .time)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(InlineStyle.captionOpacity))
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Fermer")
        }
        .padding(.horizontal, InlineStyle.horizontalPadding)
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(InlineStyle.accent)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.white.opacity(InlineStyle.captionOpacity))
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .background(
            Color.black.opacity(0.001)
                .background(.ultraThinMaterial.opacity(0.02))
        )
    }
}

private struct PreviewCard<Content: View>: View {
    let title: String
    let subtitle: String
    let accent: Color
    let content: Content

    init(title: String, subtitle: String, accent: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundColor(.white)
                        Text(subtitle)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.white.opacity(InlineStyle.captionOpacity))
                    }

                    Spacer()

                    Circle()
                        .fill(accent.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(accent)
                        )
                }

                content
                    .clipShape(RoundedRectangle(cornerRadius: InlineStyle.smallRadius, style: .continuous))
            }
        }
    }
}

private struct PremiumCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(InlineStyle.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: InlineStyle.cardRadius, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: InlineStyle.cardRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 0.6)
            )
    }
}

private struct InfluencerCarousel: View {
    let attachments: [PremiumCalendarAttachment]
    let previewKind: (PremiumCalendarAttachment) -> AttachmentPreviewKind
    let onOpen: (PremiumCalendarAttachment) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: InlineStyle.gridSpacing) {
                ForEach(attachments) { attachment in
                    MediaTile(attachment: attachment,
                              previewKind: previewKind(attachment),
                              onOpen: { onOpen(attachment) })
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct MediaTile: View {
    let attachment: PremiumCalendarAttachment
    let previewKind: AttachmentPreviewKind
    let onOpen: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: onOpen) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: InlineStyle.cardRadius, style: .continuous)
                    .fill(Color.white.opacity(0.12))

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .overlay(
                            LinearGradient(colors: [
                                Color.black.opacity(0.55),
                                Color.black.opacity(0.05)
                            ], startPoint: .bottom, endPoint: .top)
                        )
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
                            .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(attachment.title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text(previewKind == .video ? "Vidéo" : "Photo")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(InlineStyle.secondaryTextOpacity))
                }
                .padding(12)

                if previewKind == .video {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .frame(width: 230, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: InlineStyle.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: InlineStyle.cardRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
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

private struct PostTile: View {
    let post: ChallengePost
    let thumbnailURL: URL?
    let medalIconName: String?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: InlineStyle.smallRadius, style: .continuous)
                .fill(Color.white.opacity(0.08))

            if let thumbnailURL {
                AsyncCachedImage(url: thumbnailURL)
                    .scaledToFill()
                    .clipped()
                    .overlay(
                        LinearGradient(colors: [
                            Color.black.opacity(0.7),
                            Color.black.opacity(0.05)
                        ], startPoint: .bottom, endPoint: .top)
                    )
            }

            HStack(spacing: 6) {
                Text(post.authorName)
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Capsule())

                if let medalIconName {
                    MedalIconView(iconName: medalIconName)
                        .frame(width: 18, height: 18)
                        .padding(6)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }
            }
            .padding(8)
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: InlineStyle.smallRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: InlineStyle.smallRadius, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
        )
    }
}

private struct AttachmentRow: View {
    let attachment: PremiumCalendarAttachment

    private var iconName: String {
        switch attachment.kind {
        case .media: return "play.rectangle.fill"
        case .pdf: return "doc.richtext.fill"
        }
    }

    private var sizeLabel: String? {
        guard let url = attachment.localFileURL else { return nil }

        return ByteCountFormatter.string(fromByteCount: fileSize(url: url), countStyle: .file)
    }

    var body: some View {
        PremiumCard {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.white, Color.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(attachment.title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        Text(attachment.kind == .pdf ? "Document PDF" : "Média premium")
                        if let sizeLabel {
                            Text("• \(sizeLabel)")
                        }
                    }
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(InlineStyle.secondaryTextOpacity))
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
        }
    }

    private func fileSize(url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }
}

private struct JokerRow: View {
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
        PremiumCard {
            HStack(alignment: .top, spacing: 12) {
                JokerIconView(size: 30, isDimmed: false)
                    .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 6) {
                    Text(usage.participantName)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(InlineStyle.secondaryTextOpacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct EmptyStateView: View {
    let text: String

    var body: some View {
        PremiumCard {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(InlineStyle.accent)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(text)
                    .font(.system(.callout, design: .rounded))
                    .foregroundColor(.white.opacity(InlineStyle.secondaryTextOpacity))

                Spacer(minLength: 0)
            }
        }
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
