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

    var body: some View {
        ZStack {
            // Fond dégradé plus profond
            LinearGradient(
                colors: [
                    Color(red: 27/255, green: 40/255, blue: 74/255),
                    Color(red: 21/255, green: 73/255, blue: 114/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // HEADER
                HStack {
                    Button(action: { DispatchQueue.main.async { dismiss() } }) {
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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        ForEach(0..<viewModel.duration, id: \.self) { day in
                            notificationDayCard(for: day)
                        }

                        // Bouton "Réinitialiser tout"
                        Button(action: viewModel.resetAll) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Réinitialiser tout")
                            }
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 28)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [
                                            Color.purple.opacity(0.85),
                                            Color.accentColor.opacity(0.85)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            )
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 8)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }

                // CTA Enregistrer
                Button(action: {
                    viewModel.updateNotificationConfig()
                    dismiss()
                }) {
                    Text("Enregistrer")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 82/255, green: 207/255, blue: 144/255),
                                    Color(red: 27/255, green: 188/255, blue: 155/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(Color(red: 9/255, green: 34/255, blue: 44/255))
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)
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
        VStack(alignment: .leading, spacing: 16) {
            // En-tête de carte
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 46, height: 46)
                    Image(systemName: "bell.badge.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, Color.orange)
                        .font(.system(size: 22, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Jour \(day + 1)")
                        .foregroundColor(.white)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                    Text("Rappels motivants pour rester sur votre lancée")
                        .foregroundColor(Color.white.opacity(0.72))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }

                Spacer()

                Button(action: { viewModel.duplicateDay(day) }) {
                    Label("Dupliquer les rappels de ce jour", systemImage: "arrow.triangle.2.circlepath")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 250/255, green: 223/255, blue: 86/255))
                        .padding(10)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.28), radius: 8, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dupliquer les rappels de ce jour")
            }

            // Liste des heures
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.notificationConfig[day].times, id: \.self) { time in
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 252/255, green: 250/255, blue: 240/255))

                        DatePicker(
                            "",
                            selection: Binding(
                                get: { time },
                                set: { newValue in
                                    viewModel.updateTime(for: day, oldTime: time, newTime: newValue)
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .colorScheme(.dark)

                        Spacer()

                        Button(action: {
                            viewModel.removeTime(for: day, time: time)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(red: 255/255, green: 112/255, blue: 112/255))
                                .font(.system(size: 20, weight: .semibold))
                                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Supprimer le rappel")
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color.white.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                }
            }

            // Ajouter une heure
            if viewModel.notificationConfig[day].times.count < 3 {
                Button(action: {
                    viewModel.addTime(for: day, date: Date())
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(red: 247/255, green: 255/255, blue: 143/255))
                            .font(.system(size: 20, weight: .semibold))
                        Text("Ajouter un rappel")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color.white.opacity(0.14))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 58/255, green: 107/255, blue: 173/255).opacity(0.88),
                            Color(red: 47/255, green: 146/255, blue: 200/255).opacity(0.76)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 16)
    }
}

extension Date: Identifiable {
    public var id: String {
        ISO8601DateFormatter().string(from: self)
    }
}
