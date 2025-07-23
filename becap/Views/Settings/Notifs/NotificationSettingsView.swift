//
//  NotificationSettingsView.swift
//  becap
//
//  Created by Adam Mabrouki on 16/07/2025.
//

import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject var vm: NotificationSettingsViewModel
    let onSave: ([ChallengeNotification]) -> Void  // <-- ajout closure
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Notifications")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 42)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 24)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(0..<vm.duration, id: \.self) { day in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Jour \(day + 1)")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                    Spacer()
                                    Button("Dupliquer à tous") {
                                        vm.duplicateDay(day)
                                    }
                                    .font(.caption)
                                }
                                ForEach(vm.notificationConfig[day].times, id: \.self) { time in
                                    HStack {
                                        DatePicker(
                                            "",
                                            selection: Binding(
                                                get: { time },
                                                set: { newVal in
                                                    if let i = vm.notificationConfig[day].times.firstIndex(of: time) {
                                                        vm.notificationConfig[day].times[i] = newVal
                                                    }
                                                }
                                            ),
                                            displayedComponents: .hourAndMinute
                                        )
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                        Spacer()
                                        Button {
                                            if let i = vm.notificationConfig[day].times.firstIndex(of: time) {
                                                vm.removeTime(for: day, at: i)
                                            }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                if vm.notificationConfig[day].times.count < 3 {
                                    Button {
                                        vm.addTime(for: day, date: Date())
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
                            vm.resetAll()
                        }
                        .padding()
                    }
                    .padding()
                }

                Button("Enregistrer") {
                    onSave(vm.updatedConfig) // <-- ici sauvegarde via closure
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
