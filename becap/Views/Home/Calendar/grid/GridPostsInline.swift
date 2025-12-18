//
//  GridPostsInline.swift
//  becap
//
//  Created by Adam Mabrouki on 04/09/2025.
//

import SwiftUI
import AVKit
import QuickLook

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
    private var hasPosts: Bool { !cell.posts.isEmpty }
    private var hasAttachments: Bool { !cell.premiumAttachments.isEmpty }
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

                    if hasAttachments {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Contenus premium ➕")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundColor(.white)

                            ForEach(cell.premiumAttachments) { attachment in
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
        guard let url = attachment.localFileURL else { return }

        switch attachment.kind {
        case .pdf:
            quickLookURL = url
        case .media:
            videoURL = url
        }
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
