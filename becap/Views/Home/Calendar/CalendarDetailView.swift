//
//  CalendarDetailView.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//
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

// MARK: - Main View
struct CalendarDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CalendarDetailViewModel

    @State private var selectedParticipant: Participant?
    @State private var selectedGridCell: CalendarDetailCell?
    @State private var showNotifSheet = false
    @State private var showJoinSheet = false
    @State private var pagerInfo: PagerInfo?

    init(challenge: Challenge) {
        _viewModel = StateObject(wrappedValue: CalendarDetailViewModel(challenge: challenge))
    }

    var body: some View {
        ZStack {
            LinearGradient.petrolToSky.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Text(viewModel.challenge.title)
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal)
                    .padding(.top, 6)
                    .padding(.bottom, 10)

                participantFilter
                    .frame(height: 42)
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                // Apple-style month grid
                monthGrid

                Spacer(minLength: 0)
            }
        }
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
                        GridPhotosInline(
                            cell: cell,
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
                            }
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .sheet(item: $pagerInfo) { info in
            CalendarPhotoPagerView(
                photos: info.photos,
                startIndex: info.index,
                getParticipant: { viewModel.getParticipant(for: $0) },
                onDelete: { _ in },
                onClose: { pagerInfo = nil }
            )
        }
        .onAppear { viewModel.fetchInfos() }
        .refreshable { viewModel.fetchInfos() }
        .navigationBarHidden(true)
    }

    // MARK: - Month Grid (w/ precomputed counts)
    private var monthGrid: some View {
        let cells = viewModel.buildDetailcells(for: selectedParticipant)
        let photoCountByDay: [Date: Int] = {
            var map: [Date: Int] = [:]
            map.reserveCapacity(cells.count)
            for c in cells {
                map[startOfDay(c.date)] = c.photos.count
            }
            return map
        }()

        return CalendarMonthGrid(
            startDate: viewModel.challenge.startDate,
            days: viewModel.challenge.duration,
            selectedDate: selectedGridCell?.date,
            photoCountByDay: photoCountByDay,
            onSelectDate: { date in
                let day = startOfDay(date)
                if let cell = cells.first(where: { sameDay($0.date, day) }),
                   !cell.photos.isEmpty {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        selectedGridCell = cell
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
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: { showNotifSheet = true }) {
                        GlassCircleIcon(systemName: "bell.fill")
                    }
                    Button(action: { showJoinSheet = true }) {
                        GlassCircleIcon(systemName: "square.and.arrow.up.fill")
                    }
                }
                .sheet(isPresented: $showNotifSheet, onDismiss: {
                    viewModel.fetchInfos()
                }) {
                    NotificationSettingsView(challenge: viewModel.challenge)
                }
                .sheet(isPresented: $showJoinSheet) {
                    JoinChallengeView()
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
        }
    }

    // MARK: - Participant filter
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
}

