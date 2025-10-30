//
//  CalendarDetailView.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

// TODO: Stocker ça autre part, sont également utilisées dans CalendarMonthGrid.swift
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
    @State private var showJoinSheet = false
    @State private var pagerInfo: PagerInfo?
    @State private var hasHandledInitialPhoto = false

    private let initialPhotoId: String?

    init(challenge: Challenge, initialPhotoId: String? = nil) {
        _viewModel = StateObject(wrappedValue: CalendarDetailViewModel(challenge: challenge))
        self.initialPhotoId = initialPhotoId
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
                        buildGridPhotos(cell: cell)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .sheet(item: $pagerInfo) { info in
            CalendarPhotoPagerView(photos: info.photos,
                                   startIndex: info.index,
                                   getParticipant: { viewModel.getParticipant(for: $0) },
                                   onDelete: { viewModel.deletePhoto($0) },
                                   onClose: { pagerInfo = nil })
        }
        .onAppear { viewModel.fetchInfos() }
        .refreshable { viewModel.fetchInfos() }
        .onChange(of: viewModel.allPhotos) { _ in
            handleInitialPhotoIfNeeded()
        }
        .onChange(of: viewModel.doneLoadingPhotos) { isDone in
            guard isDone else { return }
            handleInitialPhotoIfNeeded()
        }
        .navigationBarHidden(true)
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
                    GlassCircleIcon(systemName: "bell.fill")
                        .onTapGesture { showNotifSheet = true }
                    GlassCircleIcon(systemName: "square.and.arrow.up.fill")
                        .onTapGesture { showJoinSheet = true }
                }
                .sheet(isPresented: $showNotifSheet, onDismiss: { viewModel.fetchInfos() }) {
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
}

extension CalendarDetailView {
    private func handleInitialPhotoIfNeeded() {
        guard !hasHandledInitialPhoto,
              let targetId = initialPhotoId,
              viewModel.allPhotos.contains(where: { $0.id == targetId }) else { return }

        hasHandledInitialPhoto = true

        let cells = viewModel.buildDetailcells()
        guard let cell = cells.first(where: { $0.photos.contains(where: { $0.id == targetId }) }),
              let index = cell.photos.firstIndex(where: { $0.id == targetId }) else { return }

        DispatchQueue.main.async {
            pagerInfo = PagerInfo(photos: cell.photos, index: index, date: cell.date)
        }
    }
}
