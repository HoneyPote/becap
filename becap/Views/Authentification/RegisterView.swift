//
//  RegisterView.swift
//  becap
//
//  Created by Victor Derveaux on 17/07/2025.
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var authViewModel: AuthentificationViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 11 / 255, green: 44 / 255, blue: 87 / 255),
                        Color(red: 45 / 255, green: 110 / 255, blue: 166 / 255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    WaterHeaderView(title: "Créer un compte",
                                    accessoryText: "Sign In",
                                    accessoryIcon: "person.crop.circle",
                                    leadingAction: { dismiss() })
                    .frame(height: proxy.size.height * 0.5)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            VStack(spacing: 18) {
                                labeledField(title: "Nom") {
                                    TextField("Votre nom", text: $name)
                                        .textInputAutocapitalization(.words)
                                        .disableAutocorrection(true)
                                }

                                labeledField(title: "Email") {
                                    TextField("nom@email.com", text: $email)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .disableAutocorrection(true)
                                }

                                labeledField(title: "Mot de passe") {
                                    SecureField("••••••••••", text: $password)
                                }
                            }
                            .padding(.horizontal, 24)

                            Button(action: {
                                authViewModel.register(email: email, password: password, name: name)
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Créer un compte")
                                        .font(.system(.headline, design: .rounded).weight(.semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .background(Color.black.opacity(0.72))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.96, green: 0.48, blue: 0.83),
                                                    Color(red: 0.95, green: 0.62, blue: 0.38)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            }
                            .padding(.horizontal, 28)

                            NavigationLink(destination: LoginView()) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.left.circle")
                                    Text("Déjà un compte ? Se connecter")
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                }
                                .foregroundColor(.white.opacity(0.9))
                            }

                            if let error = authViewModel.authError {
                                Text(error)
                                    .font(.footnote)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                        .frame(minHeight: proxy.size.height * 0.5)
                    }
                    .padding(.top, -18)
                }
            }
        }
        .buttonStyle(.hapticPlain)
        .navigationBarBackButtonHidden(true)
    }
}

private extension RegisterView {
    func labeledField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundColor(.white.opacity(0.6))

            content()
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .foregroundColor(.white)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        }
    }
}
