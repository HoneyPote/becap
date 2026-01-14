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
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 20) {
                Text("Créer un compte")
                    .font(.largeTitle.bold())

                TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                SecureField("Mot de passe", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("S'inscrire") {
                    authViewModel.register(email: email, password: password, name: name)
                }
                .buttonStyle(.borderedProminent)
                .hapticTap()

                if let error = authViewModel.authError {
                    Text(error).foregroundColor(.red).font(.caption)
                }
            .padding(.top, 32)

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
            .padding(.top, 8)
            .padding(.trailing, 4)
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
        .buttonStyle(.hapticPlain)
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
