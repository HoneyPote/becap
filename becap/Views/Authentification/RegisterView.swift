//
//  RegisterView.swift
//  becap
//
//  Created by Victor Derveaux on 17/07/2025.
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var authViewModel: AuthentificationViewModel

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 19 / 255, green: 86 / 255, blue: 94 / 255),
                    Color(red: 9 / 255, green: 25 / 255, blue: 28 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    headerCard

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
                    .hapticTap()

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
                .padding(.vertical, 24)
            }
        }
        .padding()
    }
}

private extension RegisterView {
    var headerCard: some View {
        ZStack {
            WaveCardShape()
                .fill(Color.white)
                .frame(height: 190)
                .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)

            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.black)
                    .font(.system(size: 18, weight: .bold))

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle")
                    Text("Sign In")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
                .foregroundColor(.black.opacity(0.75))
            }
            .padding(.horizontal, 28)
            .frame(height: 140, alignment: .top)

            Text("Créer un compte")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .offset(y: 36)
        }
        .padding(.horizontal, 28)
    }

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
