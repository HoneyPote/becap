//
//  AppState.swift
//  becap
//
//  Created by Victor Derveaux on 25/07/2025.
//

import Foundation

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isLoggedIn: Bool = false
}
