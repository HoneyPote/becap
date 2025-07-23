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
    @EnvironmentObject var challengeManager: ChallengeManager
    @StateObject private var vm: CalendarDetailViewModel
    @State private var selectedPagerInfo: PagerInfo?

    init(challenge: Challenge, photos: [ChallengePhoto]) {
        _vm = StateObject(wrappedValue: CalendarDetailViewModel(challenge: challenge, photos: photos))
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(vm.challenge.title)
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .padding(.top, 42)
                .padding(.bottom, 12)
                .padding(.horizontal, 24)

            // Filtre participant
            Picker("Filtrer par", selection: $vm.selectedParticipant) {
                Text("Tous").tag(String?.none)
                ForEach(vm.uniqueParticipants, id: \.self) { p in
                    Text(p).tag(Optional(p))
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 18)
            .padding(.bottom, 4)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<vm.challenge.duration, id: \.self) { i in
                        let date = Calendar.current.date(byAdding: .day, value: i, to: vm.challenge.startDate)!
                        let isToday = Calendar.current.isDateInToday(date)
                        let photosOfDay = vm.allPhotos.filter {
                            Calendar.current.isDate($0.date, inSameDayAs: date)
//                            && (vm.selectedParticipant == nil || $0.authorName == vm.selectedParticipant)
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
                    challengeManager.deletePhoto(photo) { success in
                        guard success else { return }
                        // Mets à jour la liste locale en enlevant la photo supprimée
                        let newPhotos = vm.allPhotos.filter { $0.id != photo.id }
                        vm.updatePhotos(newPhotos)
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
