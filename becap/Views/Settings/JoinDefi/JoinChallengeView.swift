//
//  JoinChallengeView.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct JoinChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel = JoinChallengeViewModel()
    @FocusState private var isFocused: Bool

    @State private var isCodeCopied = false
    @State private var showCreationToast = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    newChallengeButton
                        .cornerRadius(16)
                        .padding(.horizontal)

                    joinByCodeSection
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                    shareExistingChallengeSection
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                }
                .padding()
            }
            .background(LinearGradient.petrolToSky.ignoresSafeArea())
            .navigationTitle("Nouveau Challenge")
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text(viewModel.alertTitle), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
        .overlay(alignment: .bottom) {
            if showCreationToast {
                ToastView(message: "Défi créé avec succès 🎉", systemImage: "checkmark.circle")
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showCreationToast = false
                            }
                        }
                    }
                    .padding(.bottom, 40)
            }
        }
    }

    private var joinByCodeSection: some View {
        VStack(spacing: 16) {
            Text("Rejoindre un Challenge")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                TextField("Code à 6 chiffres", text: $viewModel.code)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
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
                            ProgressView("Création en cours...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        } else {
                            Text("Rejoindre")
                                .bold()
                        }

                        Spacer()
                    }
                }
                .padding()
                .background(Color.cyan)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }

    private var shareExistingChallengeSection: some View {
        VStack(spacing: 16) {
            Text("Partager un de mes défis")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)

            if !viewModel.userCreatedChallenges.isEmpty {
                createdChallengesPicker
                    .padding(.horizontal, 50)

                if let challenge = viewModel.selectedChallengeToShare {
                    challengeToShareCode(challenge)
                        .padding(.horizontal)
                }
            } else {
                Text("Aucun défi encore créé")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var createdChallengesPicker: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            Picker("Sélectionner un défi", selection: $viewModel.selectedChallengeToShare) {
                ForEach(viewModel.userCreatedChallenges, id: \.id) { challenge in
                    Text(challenge.title)
                        .tag(Optional(challenge))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)
        }
    }

    private func challengeToShareCode(_ challenge: Challenge) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Code :")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(challenge.code ?? "—")
                    .font(.title2.monospacedDigit())
                    .bold()
                    .foregroundColor(.primary)

                if isCodeCopied {
                    Text("Code copié ✅")
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }

            Button(action: {
                UIPasteboard.general.string = challenge.code
                withAnimation {
                    isCodeCopied = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isCodeCopied = false
                    }
                }
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.white)
                    .background(Circle().fill(.ultraThinMaterial))
                    .shadow(radius: 4)
            }
        }
    }

    private var newChallengeButton: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: NewChallengeView(challengeCreated: $showCreationToast)) {
                Label("Créer un nouveau défi", systemImage: "plus.circle")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.5, green: 0.0, blue: 0.1),
                    Color(red: 0.7, green: 0.3, blue: 0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
