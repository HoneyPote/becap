//
//  NewChallengeView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct NewChallengeView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel = NewChallengeViewModel()

    @Binding var challengeCreated: Bool

    // TODO: Découper, trop complexe
    var body: some View {
        ZStack {
            LinearGradient.petrolToSky.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Text("Créer un défi")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 36)
                        .padding(.horizontal, 18)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Nom du défi")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(.white)
                            TextField("Nom", text: $viewModel.nom)
                                .padding(14)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .font(.system(.body, design: .rounded))
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Durée (jours)")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(.white)
                            Picker("Durée", selection: $viewModel.duree) {
                                ForEach([7, 14, 30, 60, 90], id: \.self) { value in
                                    Text("\(value) jours").tag(value)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Jokers disponibles")
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(viewModel.nombreJokers)")
                                    .font(.system(.title3, design: .rounded).weight(.semibold))
                                    .foregroundColor(.white.opacity(0.85))
                            }

                            Stepper(value: $viewModel.nombreJokers,
                                    in: 0...max(0, viewModel.duree)) {
                                Text("Nombre de jokers pour le défi")
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            HStack(spacing: 8) {
                                let iconCount = min(max(viewModel.nombreJokers, 1), 8)
                                ForEach(0..<iconCount, id: \.self) { index in
                                    let isActive = index < min(viewModel.nombreJokers, iconCount)
                                    JokerIconView(size: 28,
                                                  isDimmed: !isActive)
                                        .opacity(viewModel.nombreJokers == 0 ? 0.25 : 1.0)
                                }

                                if viewModel.nombreJokers > iconCount {
                                    Text("+\(viewModel.nombreJokers - iconCount)")
                                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }

                            Text("Les jokers permettent de sauver un jour sans photo. Les participants peuvent voter pour valider un joker sur une publication si la majorité l'estime nécessaire.")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.65))
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Heure de notification")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(.white)
                            DatePicker("Heure", selection: $viewModel.heureNotification, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    GlassCard {
                        VStack {
                            if viewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView("Création en cours…")
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    Spacer()
                                }
                                .padding(.vertical, 16)
                            } else {
                                Button(action: {
                                    viewModel.createChallenge() { success in
                                        if success {
                                            challengeCreated = true
                                            dismiss()
                                        }
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "flag.fill")
                                        Text("Créer le défi")
                                    }
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [
                                            Color.blue.opacity(0.85),
                                            Color.cyan.opacity(0.88)
                                        ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.blue.opacity(0.17), radius: 7, x: 0, y: 3)
                                }
                                .disabled(!viewModel.isFormValid)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Nouveau défi")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundColor(.white)
            }
        }
    }
}
