//
//  CalendarDetailView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

//
//
//  CalendarDetailView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct PagerInfo: Identifiable {
    let id = UUID()
    let photos: [ChallengePhoto]
    let index: Int
    let date: Date
}

struct CalendarDetailView: View {
    @StateObject private var viewModel: CalendarDetailViewModel

    @State private var selectedPagerInfo: PagerInfo?

    init(challenge: Challenge) {
        _viewModel = StateObject(wrappedValue: CalendarDetailViewModel(challenge: challenge))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            filterView

            ScrollView {
                VStack(spacing: 12) {
                    if viewModel.doneLoadingPhotos, let cells = viewModel.detailCells {
                        ForEach(cells, id: \.self) { cell in
                            toDetailButton(cell: cell)
                        }
                    } else {
                        ProgressView()
                    }
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .refreshable {
            viewModel.fetchPhotos()
        }
        .background(LinearGradient.petrolToSky.ignoresSafeArea())
        .sheet(item: $selectedPagerInfo) { info in
            CalendarPhotoPagerView(
                photos: info.photos,
                startIndex: info.index,
                onDelete: { photo in
                    viewModel.deletePhoto(photo) { success in
                        guard success else { return }
                        if let pager = selectedPagerInfo {
                            let pagerPhotos = pager.photos.filter { $0.id != photo.id }
                            if pagerPhotos.isEmpty {
                                selectedPagerInfo = nil
                            } else {
                                let newIndex = min(pager.index, pagerPhotos.count-1)
                                selectedPagerInfo = PagerInfo(photos: pagerPhotos, index: newIndex, date: pager.date)
                            }
                        }
                    }
                },
                onClose: {
                    selectedPagerInfo = nil
                }
            )
        }
    }

    @ViewBuilder
    func toDetailButton(cell: CalendarDetailCell) -> some View {
        let todayBackground: AnyView = cell.isToday
        ? AnyView(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.82),
                    Color.green.opacity(0.45)
                ]),
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        : AnyView(
            Color.white.opacity(0.13)
        )

        Button {
            if !cell.photos.isEmpty {
                selectedPagerInfo = PagerInfo(photos: cell.photos, index: 0, date: cell.date)
            }
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
            .background(todayBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(cell.photos.isEmpty)
    }

    var headerView: some View {
        HStack(alignment: .top) {
            Text(viewModel.challenge.title)
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .padding(.top, 42)
                .padding(.bottom, 12)
                .padding(.horizontal, 24)
            Spacer()
            NavigationLink(destination: NotificationSettingsView(challenge: viewModel.challenge)) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.blue))
                    .shadow(radius: 4)
            }
        }
    }

    var filterView: some View {
        Picker("Filtrer par", selection: $viewModel.selectedParticipant) {
            Text("Tous").tag(String?.none)
            ForEach(viewModel.uniqueParticipants, id: \.self) { participant in
                Text(participant).tag(Optional(participant))
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 18)
        .padding(.bottom, 4)
    }
}
