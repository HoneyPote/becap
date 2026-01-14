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
    let getParticipant: (String) -> ParticipantUIModel?
    let onClose: () -> Void
    let onOpenPager: (PagerInfo) -> Void

    @State private var presentedPreview: AttachmentPreview?

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
            InlineHeader(title: "Détails du jour", onClose: onClose)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: InlineStyle.sectionSpacing, pinnedViews: [.sectionHeaders]) {
                    if hasInfluencerMedia || hasDocuments {
                        SectionHeader(title: "Contenus premium", subtitle: "Influenceur & documents", symbol: "starPrenium")

                        HStack(spacing: InlineStyle.gridSpacing) {
                            if hasInfluencerMedia, let firstInfluencer = influencerMediaAttachments.first {
                                InfluencerCompactCard(attachment: firstInfluencer,
                                                      previewKind: previewKind(for: firstInfluencer),
                                                      count: influencerMediaAttachments.count,
                                                      onOpen: { open(attachment: firstInfluencer) })
                            }

                            if hasDocuments, let firstDocument = documentAttachments.first {
                                DocumentCompactCard(attachment: firstDocument,
                                                    count: documentAttachments.count,
                                                    onOpen: { open(attachment: firstDocument) })
                            }
                        }
                    }

                    if hasPosts {
                        Section {
                            LazyVGrid(columns: columns, spacing: InlineStyle.gridSpacing) {
                                postsView
                            }
                        } header: {
                            SectionHeader(title: "Posts du jour", subtitle: "Vos participants", symbol: "post")
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
                            SectionHeader(title: "Jokers utilisés", subtitle: "Votes & validations", symbol: "donut")
                        }
                    }
                }
                .padding(.horizontal, InlineStyle.horizontalPadding)
                .padding(.bottom, InlineStyle.bottomPadding)
            }
            .frame(maxHeight: InlineStyle.maxHeight)
        }
        .padding(.top, InlineStyle.topPadding)
        .padding(.horizontal, InlineStyle.containerInset)
        .background(InlineContainerBackground())
        .fullScreenCover(item: $presentedPreview) { preview in
            AttachmentPreviewScreen(preview: preview)
        }
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
            .buttonStyle(.hapticPlain)
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
            presentedPreview = AttachmentPreview(url: localURL, kind: kind, previewKind: previewKind)
        }
    }

    private func previewKind(for attachment: PremiumCalendarAttachment) -> AttachmentPreviewKind {
        guard attachment.kind == .media else { return .unknown }
        if let url = attachment.localFileURL {
            return previewKind(for: url)
        }

        if let remote = attachment.remoteURL, let url = URL(string: remote) {
            return previewKind(for: url)
        }

        return .unknown
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

private struct AttachmentPreview: Identifiable {
    let id = UUID()
    let url: URL
    let kind: PremiumAttachmentKind
    let previewKind: AttachmentPreviewKind
}

private struct AttachmentPreviewScreen: View {
    let preview: AttachmentPreview
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            Group {
                switch preview.kind {
                case .pdf:
                    QuickLookPreview(url: preview.url)
                case .media:
                    if preview.previewKind == .video {
                        VideoPlayer(player: AVPlayer(url: preview.url))
                    } else {
                        QuickLookPreview(url: preview.url)
                    }
                }
            }
            .ignoresSafeArea()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
            .padding(16)
        }
    }
}

private enum InlineStyle {
    static let outerSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 20
    static let gridSpacing: CGFloat = 10
    static let horizontalPadding: CGFloat = 16
    static let bottomPadding: CGFloat = 24
    static let topPadding: CGFloat = 4
    static let containerInset: CGFloat = 14
    static let containerRadius: CGFloat = 22
    static let cardRadius: CGFloat = 18
    static let smallRadius: CGFloat = 12
    static let maxHeight: CGFloat = 460
    static let compactCardHeight: CGFloat = 120
    static let accent = Color(red: 0.55, green: 0.83, blue: 0.96)
    static let secondaryTextOpacity: Double = 0.72
    static let captionOpacity: Double = 0.58
    static let headerOpacity: Double = 0.85
}

private enum AttachmentPreviewKind {
    case image
    case video
    case unknown
}

private struct InlineContainerBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: InlineStyle.containerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.12, blue: 0.16).opacity(0.98),
                        Color(red: 0.02, green: 0.07, blue: 0.09).opacity(0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: InlineStyle.containerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: InlineStyle.containerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.04), lineWidth: 0.6)
                    .padding(1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 14)
    }
}

private struct InlineHeader: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.white.opacity(InlineStyle.headerOpacity))

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
                    )
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
            Image(symbol)
                .resizable()
                        .scaledToFit()
                        .padding(5)                // pour laisser de l’air dans le 28x28
                        .foregroundColor(InlineStyle.accent) // utile seulement si ton asset est "Template"
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
                    .fill(Color.white.opacity(0.07))
                    .background(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: InlineStyle.cardRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 0.6)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6)
    }
}

private struct InfluencerCompactCard: View {
    let attachment: PremiumCalendarAttachment
    let previewKind: AttachmentPreviewKind
    let count: Int
    let onOpen: () -> Void

    @State private var thumbnail: UIImage?

    private var remoteURL: URL? {
        guard let remote = attachment.remoteURL else { return nil }
        return URL(string: remote)
    }

    var body: some View {
        Button(action: onOpen) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: InlineStyle.cardRadius, style: .continuous)
                    .fill(Color.white.opacity(0.06))

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .overlay(
                            LinearGradient(colors: [
                                Color.black.opacity(0.55),
                                Color.black.opacity(0.1)
                            ], startPoint: .bottom, endPoint: .top)
                        )
                } else if let remoteURL, previewKind == .image {
                    AsyncCachedImage(url: remoteURL)
                        .scaledToFill()
                        .clipped()
                        .overlay(
                            LinearGradient(colors: [
                                Color.black.opacity(0.55),
                                Color.black.opacity(0.1)
                            ], startPoint: .bottom, endPoint: .top)
                        )
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: previewKind == .video ? "play.circle.fill" : "photo.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white.opacity(0.75))
                        Text("Influenceur")
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Influenceur")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                    Text("\(count) média\(count > 1 ? "s" : "")")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(InlineStyle.secondaryTextOpacity))
                }
                .padding(10)
            }
            .frame(height: InlineStyle.compactCardHeight)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: InlineStyle.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: InlineStyle.cardRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
            )
            .overlay(alignment: .topTrailing) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(8)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
                    .padding(8)
            }
        }
        .buttonStyle(.hapticPlain)
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

private struct DocumentCompactCard: View {
    let attachment: PremiumCalendarAttachment
    let count: Int
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: InlineStyle.cardRadius, style: .continuous)
                    .fill(Color.white.opacity(0.06))

                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text("Documents")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)

                    Text("\(count) fichier\(count > 1 ? "s" : "")")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(InlineStyle.secondaryTextOpacity))
                }
                .padding(10)
            }
            .frame(height: InlineStyle.compactCardHeight)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: InlineStyle.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: InlineStyle.cardRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
            )
            .overlay(alignment: .topTrailing) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(8)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
                    .padding(8)
            }
        }
        .buttonStyle(.hapticPlain)
        .accessibilityLabel("Ouvrir document premium")
    }
}

private struct PostTile: View {
    let post: ChallengePost
    let thumbnailURL: URL?
    let medalIconName: String?

    private var initial: String {
        post.authorName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1).uppercased()
    }

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
            } else {
                ZStack {
                    Color.white.opacity(0.06)
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
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
            .overlay(alignment: .topLeading) {
                Text(initial)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Circle())
                    .padding(8)
            }
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

struct PremiumAttachmentRow: View {
    let attachment: PremiumCalendarAttachment

    var body: some View {
        AttachmentRow(attachment: attachment)
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
