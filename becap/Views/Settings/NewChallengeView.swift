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

    @State private var showNameError = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name
    }

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
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nom du défi")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 6) {
                                TextField("Nom", text: $viewModel.nom)
                                    .padding(16)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(14)
                                    .font(.system(.body, design: .rounded))
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(showNameError && viewModel.trimmedNom.isEmpty ? Color.red.opacity(0.9) : Color.white.opacity(0.18), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                                    .focused($focusedField, equals: .name)
                                    .onChange(of: viewModel.nom) { newValue in
                                        if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            showNameError = false
                                        }
                                    }
                                    .submitLabel(.done)
                                    .onSubmit {
                                        showNameError = viewModel.trimmedNom.isEmpty
                                    }

                                if showNameError && viewModel.trimmedNom.isEmpty {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.red.opacity(0.85))
                                        Text("Le nom du défi est obligatoire.")
                                            .font(.system(.footnote, design: .rounded))
                                            .foregroundColor(.red.opacity(0.9))
                                    }
                                    .transition(.opacity)
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Type de défi")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(.white)

                            Menu {
                                ForEach(ChallengeCategory.allCases, id: \.self) { category in
                                    Button(category.displayName) {
                                        viewModel.categorie = category
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.categorie.displayName)
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Durée du défi")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("\(viewModel.duree) jour\(viewModel.duree > 1 ? "s" : "")")
                                        .font(.system(.title3, design: .rounded).weight(.semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("Personnalisez la durée")
                                        .font(.system(.footnote, design: .rounded))
                                        .foregroundColor(.white.opacity(0.65))
                                }

                                Slider(value: Binding(
                                    get: { Double(viewModel.duree) },
                                    set: { viewModel.duree = Int($0) }
                                ), in: 3...365, step: 1) {
                                    Text("Durée")
                                } minimumValueLabel: {
                                    Text("3")
                                        .font(.system(.footnote, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                } maximumValueLabel: {
                                    Text("365")
                                        .font(.system(.footnote, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .tint(.white)

                                Stepper(value: $viewModel.duree, in: 3...365, step: 1) {
                                    Text("Ajuster jour par jour")
                                        .font(.system(.footnote, design: .rounded))
                                        .foregroundColor(.white.opacity(0.75))
                                }
                            }
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
                                    if viewModel.trimmedNom.isEmpty {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showNameError = true
                                            focusedField = .name
                                        }
                                        return
                                    }

                                    viewModel.createChallenge() { success in
                                        if success {
                                            challengeCreated = true
                                            dismiss()
                                        }
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "flag.2.crossed")
                                            .font(.system(size: 18, weight: .semibold))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Enregistrer le défi")
                                                .font(.system(.headline, design: .rounded).weight(.bold))
                                            Text("Lancez le challenge pour votre communauté")
                                                .font(.system(.caption, design: .rounded))
                                                .foregroundColor(.white.opacity(0.85))
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 20, weight: .bold))
                                    }
                                    .padding(.vertical, 18)
                                    .padding(.horizontal, 20)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [
                                            Color(hex: "#4F46E5").opacity(0.95),
                                            Color(hex: "#38BDF8").opacity(0.9)
                                        ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 18)
                                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(18)
                                    .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 10)
                                }
                                .opacity(viewModel.isFormValid ? 1 : 0.65)
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
