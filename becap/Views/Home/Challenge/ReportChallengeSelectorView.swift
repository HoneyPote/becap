//
//  ReportChallengeSelectorView.swift
//  becap
//
//  Created by OpenAI on 19/08/2025.
//

import SwiftUI

struct ReportChallengeSelectorView: View {
    let challenges: [Challenge]
    let onSelect: (Challenge) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if challenges.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 44))
                            .foregroundColor(.orange)

                        Text("Aucun défi à signaler")
                            .font(.headline)

                        Text("Vous devez participer à un défi pour pouvoir le signaler.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(Color(.systemGroupedBackground))
                } else {
                    List(challenges) { challenge in
                        Button {
                            onSelect(challenge)
                            dismiss()
                        } label: {
                            HStack {
                                Text(challenge.title)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Signaler un défi")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ReportChallengeSelectorView(
        challenges: [
            Challenge(id: "1", title: "Défi Matinal", duration: 7, startDate: .now, creatorUID: "1", participantUids: ["1"], notificationsConfig: nil, code: "ABC123")
        ],
        onSelect: { _ in }
    )
}
