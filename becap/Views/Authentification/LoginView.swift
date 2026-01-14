//
//  LoginView.swift
//  becap
//
//  Created by Victor Derveaux on 17/07/2025.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @StateObject var authViewModel = AuthentificationViewModel()

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
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

                VStack(spacing: 28) {
                    headerCard

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
                    .padding(.horizontal, 24)

                    Button(action: {
                        authViewModel.login(email: email, password: password)
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Se connecter")
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

                    VStack(spacing: 14) {
                        Text("Ou se connecter avec")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(spacing: 18) {
                            socialButton(systemName: "globe")
                            socialButton(systemName: "message")
                            socialButton(systemName: "xmark")
                            socialButton(systemName: "music.note")
                        }
                    }

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
                .padding(.horizontal)
            }
            .padding()
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden(true)
        }
    }
}

private extension LoginView {
    var headerCard: some View {
        ZStack {
            WaveCardShape()
                .fill(Color.white)
                .frame(height: 160)
                .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)

            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.black)
                    .font(.system(size: 18, weight: .bold))

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle")
                    Text("Sign Up")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
                .foregroundColor(.black.opacity(0.75))
            }
            .padding(.horizontal, 28)
            .frame(height: 120, alignment: .top)

            Text("Sign In")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .offset(y: 30)
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

    func socialButton(systemName: String) -> some View {
        Button(action: {}) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.12))
                .clipShape(Circle())
        }
        .buttonStyle(.hapticPlain)
    }
}

private struct WaveCardShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.68))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY * 0.72),
            control1: CGPoint(x: rect.maxX * 0.72, y: rect.maxY * 0.9),
            control2: CGPoint(x: rect.maxX * 0.28, y: rect.maxY * 0.5)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        return path
    }
}
