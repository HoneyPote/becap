//
//  SplashScreenViewModel.swift
//  becap
//
//  Created by Victor Derveaux on 22/07/2025.
//

import Foundation
import SwiftUI

class SplashScreenViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var fetchingAlreadyConnectedUserIsDone: Bool = false
    @Published var logoAnimIsDone: Bool = false

    private let accountManager: AccountManagerProtocol = AccountManager()

    init() {}

    func onAppear() {
        fetchAlreadyConnectedUser()
        animateLogo()
    }

    func fetchAlreadyConnectedUser() {
        guard let user = AccountService().currentUser else {
            self.fetchingAlreadyConnectedUserIsDone = true
            return
        }
        
        Task {
            do {
                if let user = try await accountManager.fetchUser(uid: user.uid) {
                    UserManager.shared.saveUser(user: user)
                }
                await MainActor.run {
                    self.isAuthenticated = true
                    self.fetchingAlreadyConnectedUserIsDone = true
                }
            } catch let error {
                print("Erreur lors de la récupération de l'utilisateur : \(error.localizedDescription)")
                await MainActor.run {
                    self.isAuthenticated = false
                    self.fetchingAlreadyConnectedUserIsDone = true
                }
            }
        }
    }

    func animateLogo() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                self.logoAnimIsDone = true
            }
        }
    }
}
