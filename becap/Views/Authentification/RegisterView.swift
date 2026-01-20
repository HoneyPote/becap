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
        ZStack {
            LinearGradient.authBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                WaterHeaderView(title: "Créer un compte")

                ScrollView(showsIndicators: false) {
                    registerForm
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    var registerForm: some View {
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
            .padding(.horizontal, 6)

            Button(action: {
                authViewModel.register(email: email, password: password, name: name)
            }, label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Créer un compte")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Color.black.opacity(0.72))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(LinearGradient.authButton, lineWidth: 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            })

            HStack(spacing: 6) {
                Image(systemName: "arrow.left.circle")

                Text("Déjà un compte ? Se connecter")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundColor(.white.opacity(0.9))
            .onTapGesture { dismiss() }

            if let error = authViewModel.authError {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
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
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                }
        }
    }
}
