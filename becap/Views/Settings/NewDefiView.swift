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

    @State private var nom = ""
    @State private var duree = 30
    @State private var heureNotification = Date()
    @State private var participantInput = ""
    @State private var participants: [String] = []

    var body: some View {
        Form {
            Section(header: Text("Nom du défi")) {
                TextField("Nom", text: $nom)
            }

            Section(header: Text("Durée (jours)")) {
                Picker("Durée", selection: $duree) {
                    ForEach([7, 14, 30, 60, 90], id: \.self) { value in
                        Text("\(value) jours").tag(value)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("Heure de notification")) {
                DatePicker("Heure", selection: $heureNotification, displayedComponents: .hourAndMinute)
            }

            Section(header: Text("Participants")) {
                HStack {
                    TextField("Prénom ou email", text: $participantInput)
                    Button("Ajouter") {
                        let trimmed = participantInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        participants.append(trimmed)
                        participantInput = ""
                    }
                }
                ForEach(participants, id: \.self) { name in
                    Text(name)
                }
            }

            Section {
                Button("Créer le défi") {
                    // Configuration des notifications par défaut : une notif par jour à la même heure
                    let config: [ChallengeNotification] = (0..<duree).map { i in
                        ChallengeNotification(dayIndex: i, times: [heureNotification])
                    }
                    let newChallenge = Challenge(
                        id: nil,
                        title: nom,
                        duration: duree,
                        startDate: Date(),
                        creatorUID: challengeManager.currentUser?.id ?? "unknown",
                        participantUids: participants, // Si tu as des UID, sinon prénom temporaire
                        status: "active",
                        notificationsConfig: config
                    )
                    ChallengeService.shared.addChallenge(newChallenge) { error in
                        if error == nil {
                            challengeManager.loadChallenges() // Recharge la liste après ajout
                            dismiss()
                        }
                        // Tu peux ajouter une gestion d'erreur ici (toast, alert...)
                    }
                }
                .disabled(nom.isEmpty || participants.isEmpty)
            }
        }
        .navigationTitle("Nouveau défi")
    }
}
