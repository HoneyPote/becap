//
//  JoinChallengeView.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

import SwiftUI

struct JoinChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    @StateObject private var viewModel = JoinChallengeViewModel()

    @State private var isCodeCopied = false
    @State private var showCreationToast = false

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
                        GlassCard {
                            shareExistingChallengeSection
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
        .overlay(alignment: .bottom) {
            if showCreationToast {
                ToastView(
                    message: "Défi créé avec succès 🎉",
                    type: .success
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { showCreationToast = false }
                    }
                }
                .padding(.bottom, 40)
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
                viewModel.joinChallenge() {
                    dismiss()
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

    private var shareExistingChallengeSection: some View {
        VStack(spacing: 16) {
            Text("Partager un de mes défis")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !viewModel.userCreatedChallenges.isEmpty {
                createdChallengesPicker
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)

                if let challenge = viewModel.selectedChallengeToShare {
                    challengeToShareCode(challenge)
                        .padding(.horizontal, 2)
                        .padding(.top, 2)
                }
            } else {
                Text("Aucun défi encore créé")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var createdChallengesPicker: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

            Picker("Sélectionner un défi", selection: $viewModel.selectedChallengeToShare) {
                ForEach(viewModel.userCreatedChallenges, id: \.id) { challenge in
                    Text(challenge.title)
                        .tag(Optional(challenge))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal, 8)
        }
        .frame(height: 54)
    }

    private func challengeToShareCode(_ challenge: Challenge) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Code à Partager:")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)

                Text(challenge.code ?? "—")
                    .font(.system(.title2, design: .monospaced).weight(.bold))
                    .foregroundColor(.accentColor)

                if isCodeCopied {
                    Text("Code copié ✅")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }
            .padding(.vertical, 2)
            Spacer()
            Button(action: {
                UIPasteboard.general.string = challenge.code
                withAnimation { isCodeCopied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { isCodeCopied = false }
                }
            }) {
                Image(systemName: "doc.on.doc.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(.ultraThinMaterial))
                    .shadow(radius: 4)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}
