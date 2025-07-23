//
//  RegisterView.swift
//  becap
//
//  Created by Victor Derveaux on 17/07/2025.
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = AuthentificationViewModel()

    @State private var email = ""
    @State private var password = ""
    @State private var name = ""

    var body: some View {
        NavigationStack {
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
                    viewModel.register(email: email, password: password, name: name)
                }
                .buttonStyle(.borderedProminent)

                if let error = viewModel.authError {
                    Text(error).foregroundColor(.red).font(.caption)
                }
            }
            .padding()
            .navigationDestination(isPresented: $viewModel.isAuthenticated) {
                MainTabView(defiManager: DefiManager())
            }
        }
    }
}
