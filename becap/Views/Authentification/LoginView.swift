//
//  LoginView.swift
//  becap
//
//  Created by Victor Derveaux on 17/07/2025.
//

import SwiftUI

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @StateObject private var viewModel = AuthentificationViewModel()

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoggedIn = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Connexion")
                .font(.largeTitle.bold())

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Mot de passe", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Se connecter") {
                viewModel.login(email: email, password: password)
            }
            .buttonStyle(.borderedProminent)

            NavigationLink("Créer un compte", destination: RegisterView())

            if let error = viewModel.authError {
                Text(error).foregroundColor(.red).font(.caption)
            }
        }
        .padding()
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
    }
}
