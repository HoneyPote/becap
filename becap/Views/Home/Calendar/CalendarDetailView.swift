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
    var photos: [ChallengePhoto]
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
    @State private var pendingInitialPhotoId: String?
    @State private var showJokerBubble = false

    init(challenge: Challenge, initialPhotoId: String? = nil) {
        _viewModel = StateObject(wrappedValue: CalendarDetailViewModel(challenge: challenge))
        _pendingInitialPhotoId = State(initialValue: initialPhotoId)
    }

    var body: some View {
        ZStack {
            LinearGradient.petrolToSky.ignoresSafeArea()

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

                // Apple-style month grid adapted to challenge length
                monthGrid

                Spacer(minLength: 0)
            }
        }
        // Bubble with the inline grid
        .overlay {
            ZStack {
                if let cell = selectedGridCell {
                    ZStack {
                        // tap-catcher UNDER the bubble
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation { selectedGridCell = nil }
                            }

                        BubbleOverlay {
                            buildGridPhotos(cell: cell)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                if showJokerBubble, let jokerStatus = viewModel.currentUserJokerStatus {
                    ZStack {
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation { showJokerBubble = false }
                            }

                        BubbleOverlay {
                            jokerBubbleContent(status: jokerStatus)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .sheet(item: $pagerInfo) { info in
            CalendarPhotoPagerView(photos: info.photos,
                                   startIndex: info.index,
                                   challenge: viewModel.challenge,
                                   getParticipant: { viewModel.getParticipant(for: $0) },
                                   onDelete: { viewModel.deletePhoto($0) },
                                   onClose: { pagerInfo = nil })
        }
        .onAppear { viewModel.fetchInfos() }
        .refreshable { viewModel.fetchInfos() }
        .navigationBarHidden(true)
        .onAppear {
            if viewModel.doneLoadingPhotos {
                openInitialPhotoIfNeeded()
            }
        }
        .onChange(of: viewModel.doneLoadingPhotos) { isDone in
            if isDone {
                openInitialPhotoIfNeeded()
            }
        }
        .onChange(of: viewModel.allPhotos) { _ in
            openInitialPhotoIfNeeded()
        }
        .onChange(of: selectedParticipant) { _ in
            showJokerBubble = false
        }
    }

    // MARK: - Month Grid (w/ precomputed counts)
    private var monthGrid: some View {
        let cells = viewModel.buildDetailcells(for: selectedParticipant)
        let photoCountByDay: [Date: Int] = {
            var map: [Date: Int] = [:]
            map.reserveCapacity(cells.count)

            for cell in cells {
                map[startOfDay(cell.date)] = cell.photos.count
            }

            return map
        }()

        let jokerCountByDay = viewModel.jokerUsageCounts(for: selectedParticipant)

        return CalendarMonthGrid(
            startDate: viewModel.challenge.startDate,
            days: viewModel.challenge.duration,
            selectedDate: selectedGridCell?.date,
            photoCountByDay: photoCountByDay,
            jokerCountByDay: jokerCountByDay,
            onSelectDate: { date in
                let day = startOfDay(date)

                if let cell = cells.first(where: { sameDay($0.date, day) }),
                   !cell.photos.isEmpty {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        selectedGridCell = cell
                        showJokerBubble = false
                    }
                }
            }
        )
        .padding(.horizontal, 14)
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
                                              photos: viewModel.allPhotos,
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
                                                      await viewModel.markChatAsRead()
                                                  }
                                              })
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

    private func buildGridPhotos(cell: CalendarDetailCell) -> some View {
        GridPhotosInline(cell: cell,
                         challengeTitle: viewModel.challenge.title,
                         getParticipant: { viewModel.getParticipant(for: $0) },
                         onClose: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                selectedGridCell = nil
            }
        },
                         onOpenPager: { info in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                selectedGridCell = nil
            }
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
                                  fillColor: .white,
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
                              fillColor: .white,
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
    }

    private func openInitialPhotoIfNeeded() {
        guard viewModel.doneLoadingPhotos,
              let photoId = pendingInitialPhotoId else { return }

        guard let photo = viewModel.allPhotos.first(where: { $0.id == photoId }) else {
            return
        }

        let cells = viewModel.buildDetailcells(for: nil)
        guard let cell = cells.first(where: { sameDay($0.date, photo.date) }),
              let index = cell.photos.firstIndex(where: { $0.id == photoId }) else {
            return
        }

        pagerInfo = PagerInfo(photos: cell.photos, index: index, date: cell.date)
        pendingInitialPhotoId = nil
    }
}
