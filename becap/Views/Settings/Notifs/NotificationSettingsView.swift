//
//  NotificationSettingsView.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: NotificationSettingsViewModel

    init(challenge: Challenge) {
        _viewModel = StateObject(wrappedValue: NotificationSettingsViewModel(currentChallenge: challenge))
    }

    // TODO: Découper davantage
    var body: some View {
        ZStack {
            LinearGradient.petrolToSky.ignoresSafeArea()
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    Button(action: {
                        DispatchQueue.main.async {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 5, x: 0, y: 2)
                    }
                    Spacer()
                    Text("Notifications")
                        .font(.system(.title, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)
                    Spacer(minLength: 36)
                }
                .padding(.horizontal)
                .padding(.top, 30)

                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(0..<viewModel.duration, id: \.self) { day in
                            notificationDayCard(for: day)
                        }

                        Button(action: viewModel.resetAll) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Réinitialiser tout")
                            }
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundColor(.pink)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 22)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .shadow(radius: 6, x: 0, y: 2)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }

                Button(action: {
                    viewModel.updateNotificationConfig()
                    dismiss()
                }) {
                    Text("Enregistrer")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentColor, Color.blue.opacity(0.72)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
                .padding(.top, 2)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - CARD PAR JOUR
    private func notificationDayCard(for day: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Jour \(day + 1)")
                    .foregroundColor(.white)
                    .font(.system(.headline, design: .rounded).bold())
                Spacer()
                Button(action: { viewModel.duplicateDay(day) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.right.fill")
                        Text("Dupliquer à tous")
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.blue)
                .padding(6)
                .background(Color.white.opacity(0.18))
                .cornerRadius(8)
            }

            ForEach(viewModel.notificationConfig[day].times, id: \.self) { time in
                HStack {
                    DatePicker("",
                               selection: Binding(get: { time },
                                                  set: { newValue in
                        viewModel.updateTime(for: day, oldTime: time, newTime: newValue)}),
                               displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .colorScheme(.dark)

                    Spacer()

                    Button(action: {
                        viewModel.removeTime(for: day, time: time)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                            .shadow(radius: 1)
                    }
                }
            }

            if viewModel.notificationConfig[day].times.count < 3 {
                Button(action: {
                    viewModel.addTime(for: day, date: Date())
                }) {
                    Label("Ajouter une heure", systemImage: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                        .padding(.top, 3)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

extension Date: Identifiable {
    public var id: String {
        ISO8601DateFormatter().string(from: self)
    }
}
