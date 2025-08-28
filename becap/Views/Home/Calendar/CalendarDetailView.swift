//
//  CalendarDetailView.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

struct PagerInfo: Identifiable {
    let id = UUID()
    var photos: [ChallengePhoto]
    var index: Int
    let date: Date
}

struct CalendarDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: CalendarDetailViewModel

    @State private var selectedParticipant: Participant?
    @State private var selectedGridCell: CalendarDetailCell?
    @State private var showNotifSheet = false
    @State private var showJoinSheet = false

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

                ScrollView {
                    VStack(spacing: 10) {
                        if viewModel.doneLoadingPhotos {
                            calendarCardList
                        } else {
                            ProgressView().padding()
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
            }
        }
        .sheet(item: $viewModel.selectedPagerInfo) { info in
            CalendarPhotoPagerView(photos: info.photos,
                                   startIndex: info.index,
                                   getParticipant: { viewModel.getParticipant(for: $0)},
                                   onDelete: { photo in viewModel.deletePhoto(photo) },
                                   onClose: { viewModel.selectedPagerInfo = nil })
        }
        .sheet(item: $selectedGridCell) { cell in
            GridPhotosSheetView(cell: cell,
                                getParticipant: { viewModel.getParticipant(for: $0) },
                                challengeTitle: viewModel.challenge.title,
                                onClose: { selectedGridCell = nil })
        }
        .onAppear { viewModel.fetchInfos() }
        .refreshable { viewModel.fetchInfos() }
        .navigationBarHidden(true)
    }

    private var calendarCardList: some View {
        ForEach(viewModel.buildDetailcells(for: selectedParticipant), id: \.self) { cell in
            CalendarCard {
                CalendarDayButtonView(cell: cell,
                                      action: { calendarDayButtonAction(for: cell) },
                                      isEnabled: !cell.photos.isEmpty)
            }
        }
    }

    private func calendarDayButtonAction(for cell: CalendarDetailCell) {
        selectedParticipant == nil ? selectedGridCell = cell : viewModel.detailButtonClicked(cell: cell)
    }

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
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
                    Button(action: {
                        showNotifSheet = true
                    }) {
                        GlassCircleIcon(systemName: "bell.fill")
                    }

                    Button(action: {
                        showJoinSheet = true
                    }) {
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
