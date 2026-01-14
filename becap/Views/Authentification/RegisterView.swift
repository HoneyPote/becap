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
        }
        .padding()
        .buttonStyle(.hapticPlain)
    }
}
