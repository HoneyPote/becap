//
//  CalendarDetailView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct PagerInfo: Identifiable {
    let id = UUID()
    var photos: [ChallengePhoto]
    var index: Int
    let date: Date
}

struct CalendarDetailView: View {
    @StateObject private var viewModel: CalendarDetailViewModel

    @State private var selectedParticipant: Participant?

    init(challenge: Challenge) {
        _viewModel = StateObject(wrappedValue: CalendarDetailViewModel(challenge: challenge))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            filterView

            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.doneLoadingPhotos {
                        ForEach(viewModel.buildDetailcells(for: selectedParticipant), id: \.self) { cell in
                            detailCellButton(cell: cell)
                        }
                    } else {
                        ProgressView()
                    }
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.fetchInfos()
        }
        .refreshable {
            viewModel.fetchInfos()
        }
        .background(LinearGradient.petrolToSky.ignoresSafeArea())
        .sheet(item: $viewModel.selectedPagerInfo) { info in
            photoPagerSheetView(info: info)
        }
    }

    func photoPagerSheetView(info: PagerInfo) -> some View {
        CalendarPhotoPagerView(
            photos: info.photos,
            startIndex: info.index,
            canDelete: viewModel.canDeletePhoto(photos: info.photos),
            onDelete: { photo in
                viewModel.deletePhoto(photo)
            },
            onClose: {
                viewModel.selectedPagerInfo = nil
            }
        )
    }

    func detailCellButton(cell: CalendarDetailCell) -> some View {
        Button {
            viewModel.detailButtonClicked(cell: cell)
        } label: {
            HStack {
                Text(cell.date, style: .date)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                if cell.isToday {
                    Text("Aujourd’hui")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(Color.green.opacity(0.95))
                        )
                        .padding(.leading, 4)
                }
                Spacer()
                Text("\(cell.photos.count) photo(s)")
                    .foregroundColor(.white.opacity(0.6))
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding()
            .background(cellBackgroundView(isToday: cell.isToday))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(cell.photos.isEmpty)
    }

    func cellBackgroundView(isToday: Bool) -> some View {
        isToday
        ? AnyView(LinearGradient(
            gradient: Gradient(colors: [Color.green.opacity(0.82),Color.green.opacity(0.45)]),
            startPoint: .topLeading, endPoint: .bottomTrailing))
        : AnyView(Color.white.opacity(0.13))
    }

    var headerView: some View {
        HStack(alignment: .top) {
            Text(viewModel.challenge.title)
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .padding(.top, 42)
                .padding(.bottom, 12)
                .padding(.leading, 24)

            Spacer()

            HStack(spacing: 12) {
                NavigationLink(destination: NotificationSettingsView(challenge: viewModel.challenge)) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(.ultraThinMaterial))
                        .shadow(radius: 4)
                }

                NavigationLink(destination: JoinChallengeView()) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(.ultraThinMaterial))
                        .shadow(radius: 4)
                }
            }
            .padding(.top, 42)
            .padding(.trailing)
        }
    }

    var filterView: some View {
        Picker("Filtrer par", selection: $selectedParticipant) {
            Text("Tous").tag(Participant?.none)
            ForEach(viewModel.participants, id: \.self) { participant in
                Text(participant.name).tag(Optional(participant))
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 18)
        .padding(.bottom, 4)
    }
}
