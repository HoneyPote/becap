//
//  NewDefiView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

//
//  NewDefiView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI


struct NewDefiView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = NewDefiViewModel()

    var body: some View {
        Form {
            Section(header: Text("Nom du défi")) {
                TextField("Nom", text: $vm.nom)
            }

            Section(header: Text("Durée (jours)")) {
                Picker("Durée", selection: $vm.duree) {
                    ForEach([7, 14, 30, 60, 90], id: \.self) { value in
                        Text("\(value) jours").tag(value)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("Heure de notification")) {
                DatePicker("Heure", selection: $vm.heureNotification, displayedComponents: .hourAndMinute)
            }

            Section {
                if vm.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Création en cours...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        Spacer()
                    }
                } else {
                    Button("Créer le défi") {
                        vm.createChallenge(using: challengeManager) { success in
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!vm.isFormValid)
                }
            }
        }
        .navigationTitle("Nouveau défi")
    }
}
