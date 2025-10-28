//
//  LegalDocumentsView.swift
//  becap
//
//  Created by OpenAI on 13/08/2025.
//

import SwiftUI

struct LegalDocumentsView: View {
    // TODO: Remplacer les URLs par les liens légaux définitifs.
    private let termsURL = URL(string: "https://becap.app/terms")!
    private let privacyURL = URL(string: "https://becap.app/privacy")!

    var body: some View {
        ZStack {
            LinearGradient.petrolToSky.ignoresSafeArea()

            List {
                Section(header: Text("Documents obligatoires")) {
                    Link(destination: termsURL) {
                        labelRow(title: "Conditions d’utilisation", systemImage: "doc.text")
                    }

                    Link(destination: privacyURL) {
                        labelRow(title: "Politique de confidentialité", systemImage: "lock.doc")
                    }
                }

                Section(header: Text("Vos droits"), footer: footerText) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Retirer un consentement", systemImage: "hand.raised")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundColor(.white)
                        Text("Vous pouvez révoquer votre accord ou demander l’effacement de vos données depuis cette page ou en contactant le support.")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .padding(.vertical, 6)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Mentions légales")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func labelRow(title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.white)
                .imageScale(.medium)
                .frame(width: 28)

            Text(title)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "arrow.up.right")
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 10)
    }

    private var footerText: some View {
        Text("Vous pouvez à tout moment consulter les conditions et demander la suppression de vos données depuis la section Paramètres > Compte.")
            .font(.footnote)
            .foregroundColor(.white.opacity(0.7))
            .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        LegalDocumentsView()
    }
}
