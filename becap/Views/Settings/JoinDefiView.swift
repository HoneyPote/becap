import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct JoinDefiView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var challengeManager: ChallengeManager
    @StateObject private var vm = JoinDefiViewModel()
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

        .onAppear {
            challengeManager.loadCurrentUser { success in
                if success {
                    Task {
                        await challengeManager.fetchAndFilterChallenges()
                        await vm.loadAllUserChallenges(challengeManager: challengeManager)
                    }
                }
            }
        }
        .alert(isPresented: $vm.showingAlert) {
            Alert(title: Text(vm.alertTitle), message: Text(vm.alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private var joinByCodeSection: some View {
        VStack(spacing: 16) {
            Text("Rejoindre un défi")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                TextField("Code à 6 chiffres", text: $vm.code)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .focused($isFocused)

                Button(action: {
                    isFocused = false
                    Task {
                        await vm.joinChallengeIfCodeValid(challengeManager: challengeManager) {
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

            if !vm.userCreatedChallenges.isEmpty {
                Picker("Sélectionner un défi", selection: $vm.selectedChallengeToShare) {
                    ForEach(vm.userCreatedChallenges, id: \.id) { challenge in
                        Text(challenge.title).tag(Optional(challenge))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)

                if let challenge = vm.selectedChallengeToShare {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Code :")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(challenge.code ?? "—")
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
