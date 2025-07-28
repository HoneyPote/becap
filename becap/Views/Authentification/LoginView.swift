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
    @StateObject var authViewModel = AuthentificationViewModel()

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
                    authViewModel.login(email: email, password: password)
                }
                .buttonStyle(.borderedProminent)

                NavigationLink("Créer un compte", destination: RegisterView(authViewModel: authViewModel))

                if let error = authViewModel.authError {
                    Text(error).foregroundColor(.red).font(.caption)
                }
            }
            .padding()
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden(true)
        }
    }
}
