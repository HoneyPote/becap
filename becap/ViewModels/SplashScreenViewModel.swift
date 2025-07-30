//
//  SplashScreenViewModel.swift
//  becap
//
//  Created by Victor Derveaux on 22/07/2025.
//

import Foundation
import SwiftUI

class SplashScreenViewModel: ObservableObject {
    @Published var fetchingAlreadyConnectedUserIsDone: Bool = false
    @Published var logoAnimIsDone: Bool = false

    private let accountManager: AccountManagerProtocol

    var isReadyToProceed: Bool {
        logoAnimIsDone && fetchingAlreadyConnectedUserIsDone
    }

    init(accountManager: AccountManagerProtocol = AccountManager()) {
        self.accountManager = accountManager
    }

    func onAppear() {
        fetchAlreadyConnectedUser()
        animateLogo()
    }

    func fetchAlreadyConnectedUser() {
        guard let currentUser = AccountService().currentUser else {
            self.fetchingAlreadyConnectedUserIsDone = true
            return
        }

        Task {
            do {
                if let currentUser = try await accountManager.fetchUser(uid: currentUser.uid) {
                    UserManager.shared.saveUser(user: currentUser)
                }

                await MainActor.run {
                    self.fetchingAlreadyConnectedUserIsDone = true
                    AppState.shared.isLoggedIn = true
                }
            } catch let error {
                print("Erreur lors de la récupération de l'utilisateur : \(error.localizedDescription)")
                await MainActor.run {
                    self.fetchingAlreadyConnectedUserIsDone = true
                }
            }
        }
    }

    private func animateLogo() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                self.logoAnimIsDone = true
            }
        }
    }
}
