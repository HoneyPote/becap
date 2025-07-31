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

    var body: some View {
        Form {
            Section(header: Text("Nom du défi")) {
                TextField("Nom", text: $viewModel.nom)
            }

            Section(header: Text("Durée (jours)")) {
                Picker("Durée", selection: $viewModel.duree) {
                    ForEach([7, 14, 30, 60, 90], id: \.self) { value in
                        Text("\(value) jours").tag(value)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("Heure de notification")) {
                DatePicker("Heure", selection: $viewModel.heureNotification, displayedComponents: .hourAndMinute)
            }

            Section {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Création en cours...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        Spacer()
                    }
                } else {
                    Button("Créer le défi") {
                        viewModel.createChallenge() { success in
                            if success {
                                challengeCreated = true 
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
        }
        .navigationTitle("Nouveau défi")
    }
}
