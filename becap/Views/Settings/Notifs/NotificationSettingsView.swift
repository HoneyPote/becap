//
//  NotificationSettingsView.swift
//  becap
//
//  Created by Adam Mabrouki on 16/07/2025.
//

import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel: NotificationSettingsViewModel

    init(challenge: Challenge) {
        _viewModel = StateObject(wrappedValue: NotificationSettingsViewModel(currentChallenge: challenge))
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Notifications")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .padding(.top, 42)
                .padding(.bottom, 12)
                .padding(.horizontal, 24)

            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(0..<viewModel.duration, id: \.self) { day in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Jour \(day + 1)")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Spacer()
                                Button("Dupliquer à tous") {
                                    viewModel.duplicateDay(day)
                                }
                                .font(.caption)
                            }
                            notificationConfiguration(for: day)
                            if viewModel.notificationConfig[day].times.count < 3 {
                                Button {
                                    viewModel.addTime(for: day, date: Date())
                                } label: {
                                    Label("Ajouter une heure", systemImage: "plus.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    Button("Réinitialiser tout") {
                        viewModel.resetAll()
                    }
                    .padding()
                }
                .padding()
            }

            Button("Enregistrer") {
                viewModel.updateNotificationConfig()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 24)
            .padding(.horizontal)
        }
        .background(LinearGradient.petrolToSky.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func notificationConfiguration(for day: Int) -> some View {
        ForEach(viewModel.notificationConfig[day].times, id: \.self) { time in
            HStack {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { time },
                        set: { newVal in
                            if let i = viewModel.notificationConfig[day].times.firstIndex(of: time) {
                                viewModel.notificationConfig[day].times[i] = newVal
                            }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .colorScheme(.dark)
                Spacer()
                Button {
                    if let i = viewModel.notificationConfig[day].times.firstIndex(of: time) {
                        viewModel.removeTime(for: day, at: i)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
            }
        }
    }
}
