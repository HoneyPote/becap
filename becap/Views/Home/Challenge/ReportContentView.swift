//
//  ReportContentView.swift
//  becap
//
//  Created by Adam Mabrouki on 13/08/2025.
//

import SwiftUI

struct ReportContentView: View {
    let challenge: Challenge
    @Binding var isSubmitting: Bool
    @Binding var errorMessage: String?
    let onSubmit: (ContentReportReason, String) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: ContentReportReason = .inappropriateDefault
    @State private var details: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Défi concerné")) {
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Section(header: Text("Motif du signalement")) {
                    Picker("Motif", selection: $selectedReason) {
                        ForEach(ContentReportReason.allCases) { reason in
                            Text(reason.displayName).tag(reason)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section(header: Text("Détails supplémentaires")) {
                    TextEditor(text: $details)
                        .frame(minHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .accessibilityIdentifier("reportDetailsTextEditor")

                    Text("Ajoutez des informations (date, description du contenu, utilisateurs impliqués…) pour nous aider à analyser le signalement.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.red)
                    }
                }
            }
            .disabled(isSubmitting)
            .navigationTitle("Signaler le défi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: submit) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Envoyer")
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func submit() {
        onSubmit(selectedReason, details)
    }
}

private extension ContentReportReason {
    static var inappropriateDefault: ContentReportReason {
        .harassment
    }
}

#Preview {
    ReportContentView(
        challenge: Challenge(title: "Marathon",
                             duration: 5,
                             startDate: Date(),
                             creatorUID: "1",
                             adminUids: [],
                             participantUids: [],
                             notificationsConfig: nil,
                             code: nil,
                             jokerConfiguration: 1),
        isSubmitting: .constant(false),
        errorMessage: .constant(nil),
        onSubmit: { _, _ in },
        onCancel: {}
    )
}
