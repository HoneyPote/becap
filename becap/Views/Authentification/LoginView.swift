//
//  LoginView.swift
//  becap
//
//  Created by Victor Derveaux on 17/07/2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthentificationViewModel()

    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack {
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
            .navigationDestination(isPresented: $viewModel.isAuthenticated) {
                MainTabView(challengeManager: ChallengeManager.shared)
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}
