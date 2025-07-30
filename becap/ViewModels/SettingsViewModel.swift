//
//  SettingsViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import Foundation
import Combine

struct MedalDisplayItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let iconName: String
    let count: Int
    let latestDate: Date
}

class SettingsViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var signoutError: String? = nil

    private var cancellables = Set<AnyCancellable>()

    private let accountManager: AccountManagerProtocol
    private let userManager: UserManager

    init(userManager: UserManager = UserManager.shared,
         accountManager: AccountManagerProtocol = AccountManager()) {
        self.userManager = userManager
        self.accountManager = accountManager

        self.currentUser = userManager.currentUser

        observeCurrentUser()
    }

    func observeCurrentUser() {
        userManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentUser in
                self?.currentUser = currentUser
            }
            .store(in: &cancellables)
    }

    func signOut() {
        Task {
            do {
                try accountManager.signOut()
                await MainActor.run {
                    AppState.shared.sessionID = UUID()
                    AppState.shared.isLoggedIn = false
                }
            } catch {
                await MainActor.run {
                    signoutError = error.localizedDescription
                }
            }
        }
    }
}

// TODO: Que faire de ça ? Si inutile, supprimer struct MedalDisplayItem
//func groupedMedals(from medals: [UserMedal]) -> [MedalDisplayItem] {
//    let grouped = Dictionary(grouping: medals, by: \.name)
//    return grouped.map { (name, medals) in
//        MedalDisplayItem(
//            name: name,
//            description: medals.first?.description ?? "",
//            iconName: medals.first?.iconName ?? "star",
//            count: medals.count,
//            latestDate: medals.map(\.achievedDate).max() ?? Date()
//        )
//    }
//    .sorted { $0.latestDate > $1.latestDate }
//}
