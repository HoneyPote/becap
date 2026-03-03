//
//  CalendarDetailView.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

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

    @State private var selectedParticipant: ParticipantUIModel?
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
    @State private var navigateToCamera = false

    init(challenge: any ChallengeRepresentable, initialPostId: String? = nil) {
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

                Group {
                    if viewModel.doneLoadingPosts {
                        monthGrid
                    } else {
                        Spacer(minLength: 0)

                        loadingView
                    }
                }

                Spacer(minLength: 0)

                if viewModel.challenge.status == .active {
                    cameraCTAButton
                }
            }
        }
        .background(
            backgroundImageView
        )
        .coordinateSpace(name: "CalendarDetailRoot")
        // Bubble with the inline grid
        .overlay {
            if let cell = selectedGridCell {
                ZStack {
                    // tap-catcher UNDER the bubble
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation { selectedGridCell = nil }
                        }

                    BubbleOverlay {
                        buildGridPosts(cell: cell)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
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
        .navigationDestination(isPresented: $navigateToCamera) {
            ChallengeCameraContainerView(challenge: viewModel.challenge)
        }
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
        let cells = viewModel.filterDetailCells(for: selectedParticipant)
        let postCountByDay: [Date: Int] = {
            var map: [Date: Int] = [:]
            map.reserveCapacity(cells.count)

            for cell in cells {
                map[startOfDay(cell.date)] = cell.posts.count
            }

            return map
        }()

        let jokerCountByDay = viewModel.jokerUsageCounts(for: selectedParticipant)

        let currentUserJokerDays: Set<Date> = {
            guard let currentUserId = viewModel.currentUserId else { return [] }

            if let selectedParticipant, selectedParticipant.userId != currentUserId {
                return []
            }

            guard let usages = viewModel.currentParticipant?.progress.jokerProgress.confirmedUsages,
                  !usages.isEmpty else {
                return []
            }

            return Set(usages.map { startOfDay($0.date) })
        }()

        let validatedDays: Set<Date> = {
            let calendar = Calendar.current

            if let selectedParticipant {
                return Set(selectedParticipant.progress.validatedDays.map { calendar.startOfDay(for: $0) })
            }

            guard let currentParticipant = viewModel.currentParticipant else {
                return []
            }

            return Set(currentParticipant.progress.validatedDays.map { calendar.startOfDay(for: $0) })
        }()

        return CalendarMonthGrid(
            startDate: viewModel.challenge.startDate,
            days: viewModel.challenge.duration,
            selectedDate: selectedGridCell?.date,
            postCountByDay: postCountByDay,
            jokerCountByDay: jokerCountByDay,
            validatedDays: validatedDays,
            currentUserJokerDays: currentUserJokerDays,
            onSelectDate: { date in
                let day = startOfDay(date)

                if let cell = cells.first(where: { sameDay($0.date, day) }),
                   (!cell.posts.isEmpty || !cell.jokers.isEmpty) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        selectedGridCell = cell
                        showJokerBubble = false
                    }
                }
            }
        )
        .padding(.horizontal, 14)
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
                    if let currentParticipant = viewModel.currentParticipant {
                        NotificationSettingsView(challenge: viewModel.challenge, currentPartipicant: currentParticipant)
                    }
                }
                .sheet(isPresented: $showParticipantsSheet) {
                    ParticipantsOverviewView(challenge: viewModel.challenge,
                                             participants: viewModel.participants,
                                             onChallengeQuit: { dismiss() })
                }
                .sheet(isPresented: $isShareSheetPresented) {
                    if !shareItems.isEmpty {
                        ShareSheet(activityItems: shareItems)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
        }
    }

    // MARK: - Filter
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
                Text("Tous").tag(ParticipantUIModel?.none)
                ForEach(viewModel.participants.filter { !$0.progress.isBlocked }, id: \.self) { participant in
                    Text(participant.userName).tag(Optional(participant))
                }
            }
            .pickerStyle(.segmented)
            .padding(4)
        }
    }

    private func presentShareSheet() {
        guard let items = ChallengeShareBuilder.makeShareItems(for: viewModel.challenge) else { return }
        shareItems = items
        isShareSheetPresented = true
    }

    private var cameraCTAButton: some View {
        Button {
            navigateToCamera = true
        } label: {
            cameraButtonContent
        }
    }

    private var cameraButtonContent: some View {
        HStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 20, weight: .bold))

            Text("Créer un nouveau post")
                .font(.system(.headline, design: .rounded).weight(.heavy))
        }
        .foregroundColor(.black)
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.86, blue: 0.33),
                    Color(red: 1.0, green: 0.75, blue: 0.18)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
    }
}

extension CalendarDetailView {
    private var calendarBackgroundImageName: String {
        viewModel.challenge.calendarBackgroundImageName
    }

    private var loadingView: some View {
        HStack {
            Text("Chargement du défi...")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundColor(.white)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
    }

    private var backgroundImageView: some View {
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
    }

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

            if viewModel.canUseJokerToday {
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

    private func openInitialPostIfNeeded() {
        guard viewModel.doneLoadingPosts,
              let postId = pendingInitialPostId else { return }

        guard let post = viewModel.allPosts.first(where: { $0.id == postId }) else {
            return
        }

        let cells = viewModel.filterDetailCells(for: nil)
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
