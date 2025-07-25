//
//  ToastModel.swift
//  becap
//
//  Created by Victor Derveaux on 24/07/2025.
//

import Foundation

enum ToastType {
    case success
    case error
}

struct Toast {
    var isShown: Bool
    var type: ToastType
    var message: String
    var timer: Timer?

    init(isShown: Bool, type: ToastType, message: String, timer: Timer? = nil) {
        self.isShown = isShown
        self.type = type
        self.message = message
        self.timer = timer
    }
}
