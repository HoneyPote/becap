//
//  JoinChallengeView.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI

struct JoinChallengeView: View {
    // ⬇️ NEW: reçoit un code prérempli (depuis le deep link)
    private let prefilledCode: String?

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    @StateObject private var viewModel = JoinChallengeViewModel()

    // ⬇️ NEW: init optionnel avec code
    init(prefilledCode: String? = nil) {
        self.prefilledCode = prefilledCode
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.petrolToSky.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 34) {
                        Text("Rejoindre un défi")
                            .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 36)
                            .padding(.horizontal, 18)

                        GlassCard {
                            joinByCodeSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .accessibilityLabel("Fermer")
                }
            }
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        // ⬇️ NEW: quand on arrive avec un code prérempli, on l’affiche
        .onAppear {
            if let code = prefilledCode, !code.isEmpty {
                viewModel.code = code
                // On évite d’ouvrir le clavier si le code est déjà rempli
                isFocused = false
            } else {
                // sinon focus sur le champ
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
        }
    }

    private var joinByCodeSection: some View {
        VStack(spacing: 18) {
            Text("Rejoindre un challenge")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Code à 6 chiffres", text: $viewModel.code)
                .keyboardType(.numberPad)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .focused($isFocused)

            Button(action: {
                isFocused = false
                viewModel.joinChallenge {
                    if prefilledCode == nil {
                        dismiss()
                    }
                }
            }) {
                HStack {
                    Spacer()
                    if viewModel.isJoining {
                        ProgressView("Connexion...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    } else {
                        Label("Rejoindre", systemImage: "arrow.right.circle.fill")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                    }
                    Spacer()
                }
            }
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.65), Color.cyan.opacity(0.9)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: Color.blue.opacity(0.16), radius: 7, x: 0, y: 2)
        }
        .padding(.vertical, 6)
    }
}
