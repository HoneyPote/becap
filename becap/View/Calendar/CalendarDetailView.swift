//
//  CalendarDetailView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

// ChallengeApp/Views/CalendarDetailView.swift

import SwiftUI

struct CalendarDetailView: View {
    @EnvironmentObject var defiManager: DefiManager
    let defi: Defi
    @State private var selectedParticipant: String? = nil
    @State private var selectedDate: Date? = nil
    @State private var showModal = false
    @State private var isEditNotifActive = false

    // Helper for days in challenge
    var days: [Date] {
        (0..<defi.duration).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: defi.startDate)
        }
    }

    // Helper to get a binding to the current defi in the manager
    private func bindingForDefi() -> Binding<Defi> {
        guard let index = defiManager.defis.firstIndex(where: { $0.id == defi.id }) else {
            fatalError("Defi not found in manager")
        }
        return $defiManager.defis[index]
    }

    var body: some View {
        VStack {
            Text(defi.name)
                .font(.title2)
                .padding(.top)

            if !defi.participants.isEmpty {
                Picker("Participant", selection: $selectedParticipant) {
                    Text("All").tag(String?.none)
                    ForEach(defi.participants, id: \.self) { name in
                        Text(name).tag(Optional(name))
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(Array(days.enumerated()), id: \.element) { (idx, date) in
                        VStack {
                            Text(formatted(date))
                                .font(.caption)

                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 80)
                                Text("📸")
                            }
                        }
                        .onTapGesture {
                            selectedDate = date
                            showModal = true
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Calendrier")
        .sheet(isPresented: $showModal) {
            if let date = selectedDate {
                PhotoListModalView(date: date, participant: selectedParticipant)
            }
        }
    }

    func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
