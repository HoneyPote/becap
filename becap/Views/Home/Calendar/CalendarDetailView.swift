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

    init(challenge: Challenge, photos: [ChallengePhoto]) {
        _viewModel = StateObject(wrappedValue: CalendarDetailViewModel(challenge: challenge, photos: photos))
    }

    var body: some View {
        VStack(spacing: 0) {
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

            // Filtre participant
            Picker("Filtrer par", selection: $viewModel.selectedParticipant) {
                Text("Tous").tag(String?.none)
                ForEach(viewModel.uniqueParticipants, id: \.self) { participant in
                    Text(participant).tag(Optional(participant))
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 18)
            .padding(.bottom, 4)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<viewModel.challenge.duration, id: \.self) { i in
                        let date = Calendar.current.date(byAdding: .day, value: i, to: viewModel.challenge.startDate)!
                        let isToday = Calendar.current.isDateInToday(date)
                        let photosOfDay = viewModel.allPhotos.filter {
                            Calendar.current.isDate($0.date, inSameDayAs: date)
                            //                            && (viewModel.selectedParticipant == nil || $0.authorName == viewModel.selectedParticipant)
                        }

                        let todayBackground: AnyView = isToday
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
                            if !photosOfDay.isEmpty {
                                selectedPagerInfo = PagerInfo(photos: photosOfDay, index: 0, date: date)
                            }
                        } label: {
                            HStack {
                                Text(date, style: .date)
                                    .foregroundColor(.white)
                                    .fontWeight(.medium)
                                if isToday {
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
                                Text("\(photosOfDay.count) photo(s)")
                                    .foregroundColor(.white.opacity(0.6))
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding()
                            .background(todayBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(photosOfDay.isEmpty)
                    }
                }
                .padding()
            }
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
}
