//
//  CalendarDetailView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

// ChallengeApp/Views/CalendarDetailView.swift

import SwiftUI

struct CalendarDetailView: View {
    var defi: Defi
    @State private var selectedParticipant: String? = nil
    @State private var selectedDate: Date? = nil
    @State private var showModal = false

    var jours: [Date] {
        (0..<defi.duree).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: defi.dateDebut)
        }
    }

    var body: some View {
        VStack {
            Text(defi.nom)
                .font(.title2)
                .padding(.top)

            if !defi.participants.isEmpty {
                Picker("Participant", selection: $selectedParticipant) {
                    Text("Tous").tag(String?.none)
                    ForEach(defi.participants, id: \.self) { name in
                        Text(name).tag(Optional(name))
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(jours, id: \.self) { date in
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
