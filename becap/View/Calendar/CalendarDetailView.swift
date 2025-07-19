//
//  CalendarDetailView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

import SwiftUI

struct PagerInfo: Identifiable {
    let id = UUID()
    let photos: [PhotoDefi]
    let index: Int
    let date: Date
}

struct CalendarDetailView: View {
    @EnvironmentObject var defiManager: DefiManager
    @StateObject private var vm: CalendarDetailViewModel
    @State private var selectedPagerInfo: PagerInfo?

    init(defi: Defi, photos: [PhotoDefi]) {
        _vm = StateObject(wrappedValue: CalendarDetailViewModel(defi: defi, photos: photos))
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(vm.defi.name)
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
                    ForEach(0..<vm.defi.duration, id: \.self) { i in
                        let date = Calendar.current.date(byAdding: .day, value: i, to: vm.defi.startDate)!
                        let isToday = Calendar.current.isDateInToday(date)
                        let photosOfDay = vm.allPhotos.filter {
                            $0.defiId == vm.defi.id &&
                            Calendar.current.isDate($0.date, inSameDayAs: date) &&
                            (vm.selectedParticipant == nil || $0.prenomAuteur == vm.selectedParticipant)
                        }

                        // === Corrige le background ici avec AnyView ===
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
                    if let idx = defiManager.photos.firstIndex(where: { $0.id == photo.id }) {
                        try? FileManager.default.removeItem(atPath: photo.imagePath)
                        defiManager.photos.remove(at: idx)
                        vm.updatePhotos(defiManager.photos)
                        if let pager = selectedPagerInfo {
                            let newPhotos = pager.photos.filter { $0.id != photo.id }
                            if newPhotos.isEmpty {
                                selectedPagerInfo = nil
                            } else {
                                let newIndex = min(pager.index, newPhotos.count-1)
                                selectedPagerInfo = PagerInfo(photos: newPhotos, index: newIndex, date: pager.date)
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
