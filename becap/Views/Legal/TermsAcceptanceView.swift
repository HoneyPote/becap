//
//  TermsAcceptanceView.swift
//  becap
//
//  Created by Adam Mabrouki on 13/08/2025.
//

import SwiftUI

struct TermsAcceptanceView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openURL) private var openURL

    // TODO: Remplacer les URLs par les liens hébergés définitifs avant la publication sur l’App Store.
    private let termsURL = URL(string: "https://becap.app/terms")!
    private let privacyURL = URL(string: "https://becap.app/privacy")!

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.petrolToSky.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header

                        policySummary

                        Spacer(minLength: 12)

                        legalLinks

                        consentButtons
                    }
                    .padding(24)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bienvenue sur Becap")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundColor(.white)

            Text("Avant de continuer, merci de lire et d’accepter nos conditions d’utilisation et notre politique de confidentialité. Elles détaillent les règles de publication, vos droits et la manière dont nous protégeons vos données.")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    private var policySummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ce qu’il faut savoir")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 10) {
                bulletRow(text: "Publiez uniquement du contenu dont vous disposez des droits et respectueux (pas de contenu violent, haineux, sexuel ou illégal).")
                bulletRow(text: "Les équipes Becap peuvent suspendre ou supprimer un compte en cas d’abus ou de non-respect des règles.")
                bulletRow(text: "Vous restez responsable des photos, vidéos et commentaires que vous partagez. Nous obtenons une licence limitée afin d’afficher vos contenus dans l’app.")
                bulletRow(text: "Un outil de signalement est disponible sur chaque défi pour remonter un contenu inapproprié.")
                bulletRow(text: "Vous pouvez demander la suppression de votre compte et de vos données à tout moment dans les paramètres.")
            }
        }
    }

    private var legalLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consulter les documents légaux")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundColor(.white)

            Button {
                openURL(termsURL)
            } label: {
                LegalLinkRow(title: "Conditions d’utilisation", systemImage: "doc.text")
            }

            Button {
                openURL(privacyURL)
            } label: {
                LegalLinkRow(title: "Politique de confidentialité", systemImage: "lock.doc")
            }
        }
    }

    private var consentButtons: some View {
        VStack(spacing: 16) {
            Button {
                appState.acceptLegalDocuments()
            } label: {
                Text("J’accepte les conditions d’utilisation et la politique de confidentialité")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.9))
                    .cornerRadius(14)
            }
            .accessibilityIdentifier("acceptLegalButton")

            Text("Si vous refusez ces conditions, vous ne pourrez pas utiliser Becap. Vous pouvez toujours consulter les documents pour en savoir plus.")
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 12)
    }

    private func bulletRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green.opacity(0.85))
                .font(.headline)
                .padding(.top, 2)

            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
    }
}

private struct LegalLinkRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.white)
                .imageScale(.medium)
                .frame(width: 26)

            Text(title)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer()

            Image(systemName: "arrow.up.right")
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
    }
}

#Preview {
    TermsAcceptanceView()
        .environmentObject(AppState.shared)
}
