//
//  NotificationCenterView.swift
//  becap
//
//  Created by ChatGPT on 2025-XX-XX.
//

import SwiftUI

struct NotificationCenterView: View {
    @StateObject private var viewModel = NotificationCenterViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.petrolToSky.ignoresSafeArea()

                content
                    .padding(.horizontal, 16)
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if hasUnreadItems {
                        Button("Tout lire") {
                            viewModel.markAllAsRead()
                        }
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                    }
                }
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var content: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            } else if viewModel.sections.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(viewModel.sections) { section in
                            VStack(alignment: .leading, spacing: 16) {
                                Text(section.title)
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundColor(.white.opacity(0.85))

                                VStack(spacing: 14) {
                                    ForEach(section.items) { item in
                                        NotificationCard(item: item) {
                                            viewModel.open(item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.6))

            Text("Aucune notification")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            Text("Vous serez alerté dès qu'il y aura du nouveau dans vos défis.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hasUnreadItems: Bool {
        viewModel.sections.contains { section in
            section.items.contains(where: { !$0.isRead })
        }
    }
}

private struct NotificationCard: View {
    let item: NotificationItemViewModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: item.accentColor).opacity(0.25))
                        .frame(width: 48, height: 48)

                    Image(systemName: item.iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: item.accentColor))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Text(item.message)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))

                        Text(item.time)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                if !item.isRead {
                    Circle()
                        .fill(Color(hex: item.accentColor))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
}
