//
//  CalendarDetailView.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI
import Combine

// MARK: - Day helpers (normalize to day precision everywhere)
private let CAL = Calendar.current
private func startOfDay(_ d: Date) -> Date { CAL.startOfDay(for: d) }
private func sameDay(_ a: Date, _ b: Date) -> Bool { CAL.isDate(a, equalTo: b, toGranularity: .day) }

// MARK: - Pager model
struct PagerInfo: Identifiable {
    let id = UUID()
    var posts: [ChallengePost]
    var index: Int
    let date: Date
}

// TODO: Mettre dans VM ce qui doit être dans VM
// MARK: - Main View
struct CalendarDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CalendarDetailViewModel

    @State private var selectedParticipant: Participant?
    @State private var selectedGridCell: CalendarDetailCell?
    @State private var showNotifSheet = false
    @State private var showParticipantsSheet = false
    @State private var isShareSheetPresented = false
    @State private var shareItems: [Any] = []
    @State private var pagerInfo: PagerInfo?
    @State private var pendingInitialPostId: String?
    @State private var showJokerBubble = false
    @State private var jokerBubbleSize = CGSize(width: 240, height: 160)
    @State private var jokerButtonFrame: CGRect = .zero
    @State private var showPremiumEditor = false
    @State private var isEditingPremiumAttachments = false
    @State private var premiumEditorDay = 1

    init(challenge: Challenge, initialPostId: String? = nil) {
        _viewModel = StateObject(wrappedValue: CalendarDetailViewModel(challenge: challenge))
        _pendingInitialPostId = State(initialValue: initialPostId)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                header

                Text(viewModel.challenge.title)
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal)
                    .padding(.top, 6)

                Text(viewModel.challenge.status.rawValue)
                    .font(.system(.caption, design: .rounded).weight(.heavy))
                    .foregroundColor(viewModel.challenge.status == .active
                                     ? Color(red: 0.55, green: 0.82, blue: 0.61)
                                     : Color(red: 1.0, green: 0.71, blue: 0.81))


                participantFilter
                    .frame(height: 42)
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                monthGrid

                if let cell = selectedGridCell {
                    buildGridPosts(cell: cell)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.top, -6)
                }

                Spacer(minLength: 0)
            }
        }
        .background(
            ZStack {
                // Filler: covers edges at any ratio
                Image(calendarBackgroundImageName)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 12)
                    .ignoresSafeArea()

                Image(calendarBackgroundImageName)
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.2))
                    .offset(x: -40)
                    .ignoresSafeArea()
            }
        )
        .coordinateSpace(name: "CalendarDetailRoot")
        .overlay {
            jockerOverlay
        }
        .sheet(item: $pagerInfo) { info in
            PostPagerView(posts: info.posts,
                          startIndex: info.index,
                          challenge: viewModel.challenge,
                          getParticipant: { viewModel.getParticipant(for: $0) },
                          onDelete: { viewModel.deletePost($0) },
                          onClose: { pagerInfo = nil })
        }
        .onAppear { viewModel.fetchInfos() }
        .refreshable { viewModel.fetchInfos() }
        .navigationBarHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: .tabBarItemReselected)) { notification in
            guard let tab = notification.object as? TabType, tab == .home else { return }
            dismiss()
        }
        .onAppear {
            if viewModel.doneLoadingPosts {
                openInitialPostIfNeeded()
            }
        }
        .onChange(of: viewModel.doneLoadingPosts) { isDone in
            if isDone {
                openInitialPostIfNeeded()
            }
        }
        .onChange(of: viewModel.allPosts) { _ in
            openInitialPostIfNeeded()
        }
        .onChange(of: selectedParticipant) { _ in
            showJokerBubble = false
        }
        .withTabBarInset()
    }

    @ViewBuilder
    private var jockerOverlay: some View {
        if showJokerBubble,
           let status = viewModel.currentUserJokerStatus,
           jokerButtonFrame != .zero {
            GeometryReader { proxy in
                let measuredWidth = jokerBubbleSize.width > 0 ? jokerBubbleSize.width : 240
                let measuredHeight = jokerBubbleSize.height > 0 ? jokerBubbleSize.height : 160

                let minX = measuredWidth / 2 + 16
                let maxX = proxy.size.width - measuredWidth / 2 - 16
                let desiredX = jokerButtonFrame.midX
                let positionedX = max(min(desiredX, maxX), minX)

                let desiredY = jokerButtonFrame.maxY + measuredHeight / 2 + 8
                let minY = measuredHeight / 2 + 16
                let maxY = proxy.size.height - measuredHeight / 2 - 16
                let positionedY = max(min(desiredY, maxY), minY)

                ZStack {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation { showJokerBubble = false }
                        }

                    BubbleOverlay {
                        jokerBubbleContent(status: status)
                    }
                    .background(
                        GeometryReader { bubbleProxy in
                            Color.clear
                                .onAppear { updateJokerBubbleSize(bubbleProxy.size) }
                                .onChange(of: bubbleProxy.size) { updateJokerBubbleSize($0) }
                        }
                    )
                    .position(x: positionedX, y: positionedY)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Month Grid (w/ precomputed counts)
    private var monthGrid: some View {
        let cells = viewModel.buildDetailcells(for: selectedParticipant)
        let postCountByDay: [Date: Int] = {
            var map: [Date: Int] = [:]
            map.reserveCapacity(cells.count)

            for cell in cells {
                map[startOfDay(cell.date)] = cell.posts.count
            }

            return map
        }()

        let jokerCountByDay = viewModel.jokerUsageCounts(for: selectedParticipant)
        let attachmentCountByDay = viewModel.attachmentCountByDay()

        let currentUserJokerDays: Set<Date> = {
            guard let currentUserId = viewModel.currentUserId else { return [] }

            if let selectedParticipant, selectedParticipant.id != currentUserId {
                return []
            }

            guard let usages = viewModel.currentUserProgress?.jokerProgress?.confirmedUsages, !usages.isEmpty else {
                return []
            }

            return Set(usages.map { startOfDay($0.date) })
        }()

        let canEditPremium = viewModel.canEditPremiumContent
        let isEditingPremium = canEditPremium && isEditingPremiumAttachments

        return VStack(spacing: 10) {
            if isEditingPremium {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.white)
                    Text("Mode édition premium : appuie sur + d’un jour pour ajouter un média ou PDF.")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .transition(.opacity)
            }

            CalendarMonthGrid(
                startDate: viewModel.challenge.startDate,
                days: viewModel.challenge.duration,
                selectedDate: selectedGridCell?.date,
                postCountByDay: postCountByDay,
                attachmentCountByDay: attachmentCountByDay,
                jokerCountByDay: jokerCountByDay,
                currentUserJokerDays: currentUserJokerDays,
                isEditingPremiumContent: isEditingPremium,
                onSelectDate: { date in
                    let day = startOfDay(date)

                    if let cell = cells.first(where: { sameDay($0.date, day) }),
                       (!cell.posts.isEmpty || !cell.jokers.isEmpty || !cell.premiumAttachments.isEmpty) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            selectedGridCell = cell
                            showJokerBubble = false
                        }
                    }
                },
                onAddAttachmentForDay: { day in
                    premiumEditorDay = day
                    showPremiumEditor = true
                }
            )
            .padding(.horizontal, 14)
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                    .onTapGesture { dismiss() }

                Spacer()

                HStack(spacing: 12) {
                    if let jokerStatus = viewModel.currentUserJokerStatus {
                        jokerHeaderButton(status: jokerStatus)
                    }

                    GlassCircleIcon(systemName: "bell.fill")
                        .onTapGesture {
                            showJokerBubble = false
                            showNotifSheet = true
                        }
                    GlassCircleIcon(systemName: "square.and.arrow.up.fill")
                        .onTapGesture {
                            showJokerBubble = false
                            presentShareSheet()
                        }
                    if viewModel.canEditPremiumContent {
                        premiumQuickAddButton
                        GlassCircleIcon(systemName: isEditingPremiumAttachments ? "checkmark.circle.fill" : "pencil.circle.fill")
                            .onTapGesture {
                                showJokerBubble = false
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.85)) {
                                    isEditingPremiumAttachments.toggle()
                                }
                            }
                    }
                    GlassCircleIcon(systemName: "person.2.fill")
                        .overlay(alignment: .topTrailing) {
                            if viewModel.chatHasUnreadMessages {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 1.2)
                                    )
                                    .offset(x: 6, y: -6)
                                    .accessibilityHidden(true)
                            }
                        }
                        .onTapGesture {
                            showJokerBubble = false
                            showParticipantsSheet = true
                        }
                }
                .sheet(isPresented: $showNotifSheet, onDismiss: { viewModel.fetchInfos() }) {
                    NotificationSettingsView(challenge: viewModel.challenge)
                }
                .sheet(isPresented: $showParticipantsSheet) {
                    ParticipantsOverviewView(participants: viewModel.participants,
                                             posts: viewModel.allPosts,
                                             progresses: viewModel.participantProgresses,
                                             chatMessages: viewModel.chatMessages,
                                             hasUnreadMessages: viewModel.chatHasUnreadMessages,
                                             currentUserId: viewModel.currentUserId,
                                             jokerConfiguration: viewModel.challenge.jokerConfiguration,
                                             onSendMessage: { message in
                        await viewModel.sendChatMessage(content: message)
                    },
                                             onToggleReaction: { message, reaction in
                        await viewModel.toggleReaction(reaction, for: message)
                    },
                                             onChatOpened: {
                        Task {
                            viewModel.markChatAsRead()
                        }
                    })
                }
                .sheet(isPresented: $isShareSheetPresented) {
                    if !shareItems.isEmpty {
                        ShareSheet(activityItems: shareItems)
                    }
                }
                .sheet(isPresented: $showPremiumEditor) {
                    PremiumAttachmentEditorView(viewModel: viewModel,
                                                selectedDay: $premiumEditorDay,
                                                isPresented: $showPremiumEditor)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
        }
    }

    private var participantFilter: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.6)
                )

            Picker("Filtrer par", selection: $selectedParticipant) {
                Text("Tous").tag(Participant?.none)
                ForEach(viewModel.participants, id: \.self) { participant in
                    Text(participant.name).tag(Optional(participant))
                }
            }
            .pickerStyle(.segmented)
            .padding(4)
        }
    }

    private func buildGridPosts(cell: CalendarDetailCell) -> some View {
        GridPostsInline(cell: cell,
                        getParticipant: { viewModel.getParticipant(for: $0) },
                        onClose: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                selectedGridCell = nil
            }
        },
                        onOpenPager: { info in
            DispatchQueue.main.async {
                pagerInfo = info
            }
        })
    }

    private func presentShareSheet() {
        guard let items = ChallengeShareBuilder.makeShareItems(for: viewModel.challenge) else { return }
        shareItems = items
        isShareSheetPresented = true
    }
}

extension CalendarDetailView {
    private var calendarBackgroundImageName: String {
        viewModel.challenge.calendarBackgroundImageName
    }

    @ViewBuilder
    private func jokerBubbleContent(status: (total: Int, remaining: Int)) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Mes jokers")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(status.remaining)/\(status.total)")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white.opacity(0.85))
            }

            HStack(spacing: 8) {
                let displayCount = min(status.total, 8)
                ForEach(0..<displayCount, id: \.self) { index in
                    let isActive = index < min(status.remaining, displayCount)
                    JokerIconView(size: 26,
                                  isDimmed: !isActive)
                }

                if status.total > displayCount {
                    Text("+\(status.total - displayCount)")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            if viewModel.canUseJokerToday() {
                Button(action: {
                    showJokerBubble = false
                    viewModel.useJokerForToday()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Utiliser un joker aujourd'hui")
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            } else {
                Text("Journée déjà validée ou aucun joker disponible.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }
        }
    }

    @ViewBuilder
    private func jokerHeaderButton(status: (total: Int, remaining: Int)) -> some View {
        let borderColor = showJokerBubble ? Color.white.opacity(0.6) : Color.white.opacity(0.19)
        let borderWidth: CGFloat = showJokerBubble ? 1.2 : 0.7

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                let willShow = !showJokerBubble
                showJokerBubble = willShow
                if willShow {
                    selectedGridCell = nil
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .shadow(color: Color.black.opacity(0.19), radius: 5, x: 0, y: 7)

                JokerIconView(size: 22,
                              isDimmed: status.remaining == 0)
            }
            .overlay(alignment: .bottomTrailing) {
                if status.total > 0 {
                    Text("\(status.remaining)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                        .offset(x: 2, y: 4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Afficher mes jokers")
        .background(
            GeometryReader { proxy in
                let frame = proxy.frame(in: .named("CalendarDetailRoot"))

                Color.clear
                    .onAppear {
                        updateJokerButtonFrame(frame)
                    }
                    .onChange(of: frame) { updateJokerButtonFrame($0) }
            }
        )
    }

    private func dayIndex(from date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: viewModel.challenge.startDate)
        let target = calendar.startOfDay(for: date)
        let diff = calendar.dateComponents([.day], from: start, to: target).day ?? 0
        let maxDay = max(1, viewModel.challenge.duration)
        return min(max(diff + 1, 1), maxDay)
    }

    @ViewBuilder
    private var premiumQuickAddButton: some View {
        ZStack {
            GlassCircleIcon(systemName: "photo")

            Image(systemName: "plus.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .background(Color.clear)
                .offset(x: 8, y: -12)
        }
        .onTapGesture {
            showJokerBubble = false
            premiumEditorDay = dayIndex(from: selectedGridCell?.date ?? Date())
            showPremiumEditor = true
        }
        .accessibilityLabel("Ajouter un média premium")
    }

    private func openInitialPostIfNeeded() {
        guard viewModel.doneLoadingPosts,
              let postId = pendingInitialPostId else { return }

        guard let post = viewModel.allPosts.first(where: { $0.id == postId }) else {
            return
        }

        let cells = viewModel.buildDetailcells(for: nil)
        guard let cell = cells.first(where: { sameDay($0.date, post.date) }),
              let index = cell.posts.firstIndex(where: { $0.id == postId }) else {
            return
        }

        pagerInfo = PagerInfo(posts: cell.posts, index: index, date: cell.date)
        pendingInitialPostId = nil
    }

    private func updateJokerBubbleSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        let normalized = CGSize(width: size.width.rounded(.toNearestOrEven),
                                height: size.height.rounded(.toNearestOrEven))

        guard abs(jokerBubbleSize.width - normalized.width) > 0.5 ||
                abs(jokerBubbleSize.height - normalized.height) > 0.5 else {
            return
        }

        DispatchQueue.main.async {
            jokerBubbleSize = normalized
        }
    }

    private func updateJokerButtonFrame(_ frame: CGRect) {
        guard frame.width > 0, frame.height > 0 else { return }

        let normalized = CGRect(x: frame.origin.x.rounded(.toNearestOrEven),
                                y: frame.origin.y.rounded(.toNearestOrEven),
                                width: frame.size.width.rounded(.toNearestOrEven),
                                height: frame.size.height.rounded(.toNearestOrEven))

        guard abs(jokerButtonFrame.midX - normalized.midX) > 0.5 ||
                abs(jokerButtonFrame.midY - normalized.midY) > 0.5 else {
            return
        }

        DispatchQueue.main.async {
            jokerButtonFrame = normalized
        }
    }
}
