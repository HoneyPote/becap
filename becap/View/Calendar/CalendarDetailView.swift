//
//  CalendarDetailView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

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

            // Picker de filtre par participant
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
                        let photosOfDay = vm.allPhotos.filter {
                            $0.defiId == vm.defi.id &&
                            Calendar.current.isDate($0.date, inSameDayAs: date) &&
                            (vm.selectedParticipant == nil || $0.prenomAuteur == vm.selectedParticipant)
                        }
                        Button {
                            // Ouvre le carrousel si au moins une photo ce jour-là
                            if !photosOfDay.isEmpty {
                                selectedPagerInfo = PagerInfo(photos: photosOfDay, index: 0, date: date)
                            }
                        } label: {
                            HStack {
                                Text(date, style: .date)
                                    .foregroundColor(.white)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(photosOfDay.count) photo(s)")
                                    .foregroundColor(.white.opacity(0.6))
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding()
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding()
            }
        }
        .background(LinearGradient.petrolToSky.ignoresSafeArea())
        // Carrousel
        .sheet(item: $selectedPagerInfo) { info in
            CalendarPhotoPagerView(
                photos: info.photos,
                startIndex: info.index,
                onDelete: { photo in
                    // Suppression réelle dans le manager + refresh VM
                    if let idx = defiManager.photos.firstIndex(where: { $0.id == photo.id }) {
                        // Efface le fichier image du disque (optionnel)
                        try? FileManager.default.removeItem(atPath: photo.imagePath)
                        // Retire la photo du manager
                        defiManager.photos.remove(at: idx)
                        // Refresh VM avec les photos à jour
                        vm.updatePhotos(defiManager.photos)
                        // Met à jour la modale si besoin (plus de photos, ou index change)
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
