//
//  LoginView.swift
//  becap
//
//  Created by Victor Derveaux on 17/07/2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject var authViewModel = AuthentificationViewModel()

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.authBackground
                    .ignoresSafeArea()

                VStack(spacing: .zero) {
                    WaterHeaderView(title: "Connexion")

                    ScrollView(showsIndicators: false) {
                        loginForm
                            .padding(.horizontal)
                            .padding(.vertical, 16)
                     }
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden(true)
        }
    }

    var loginForm: some View {
        VStack(spacing: 28) {
            VStack(spacing: 18) {
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
                authViewModel.login(email: email, password: password)
            }, label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Se connecter")
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

            // TODO: Voir si on rend ça fonctionnel ou pas
//            VStack(spacing: 14) {
//                Text("Ou se connecter avec")
//                    .font(.system(.footnote, design: .rounded))
//                    .foregroundColor(.white.opacity(0.7))
//
//                HStack(spacing: 18) {
//                    socialButton(systemName: "globe")
//                    socialButton(systemName: "message")
//                    socialButton(systemName: "xmark")
//                    socialButton(systemName: "music.note")
//                }
//            }

            NavigationLink(destination: RegisterView(authViewModel: authViewModel)) {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle")

                    Text("Créer un compte")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
                .foregroundColor(.white.opacity(0.9))
            }
            .padding(.bottom, 8)

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

private extension LoginView {
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

    func socialButton(systemName: String) -> some View {
        Button(action: {}) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.12))
                .clipShape(Circle())
        }
    }
}

extension LinearGradient {
    static let authBackground = LinearGradient(
        colors: [Color(red: 11 / 255, green: 44 / 255, blue: 87 / 255),
                 Color(red: 45 / 255, green: 110 / 255, blue: 166 / 255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let authButton = LinearGradient(
        colors: [Color(red: 0.96, green: 0.48, blue: 0.83),
                 Color(red: 0.95, green: 0.62, blue: 0.38)],
        startPoint: .leading,
        endPoint: .trailing
    )
}
