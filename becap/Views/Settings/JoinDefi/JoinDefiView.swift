import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct JoinDefiView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = JoinDefiViewModel()

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    joinByCodeSection
                    shareExistingChallengeSection
                }
                .padding()
            }
            .background(LinearGradient.petrolToSky.ignoresSafeArea())
            .navigationTitle("Défis")
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text(viewModel.alertTitle), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private var joinByCodeSection: some View {
        VStack(spacing: 16) {
            Text("Rejoindre un défi")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                TextField("Code à 6 chiffres", text: $viewModel.code)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .focused($isFocused)

                Button(action: {
                    isFocused = false
                    Task {
                        try await viewModel.joinChallengeIfCodeValid() {
                            dismiss()
                        }
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("Rejoindre")
                            .bold()
                        Spacer()
                    }
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var shareExistingChallengeSection: some View {
        VStack(spacing: 16) {
            Text("Partager un de mes défis")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            if !viewModel.userCreatedChallenges.isEmpty {
                Picker("Sélectionner un défi", selection: $viewModel.selectedChallengeToShare) {
                    ForEach(viewModel.userCreatedChallenges, id: \.id) { challenge in
                        Text(challenge.title).tag(Optional(challenge))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)

                if let challenge = viewModel.selectedChallengeToShare {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Code :")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(challenge.code ?? "—")
                                .foregroundColor(.black)
                                .font(.title2.monospacedDigit())
                                .bold()
                        }
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = challenge.code
                        }) {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("Aucun défi créé encore")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}
