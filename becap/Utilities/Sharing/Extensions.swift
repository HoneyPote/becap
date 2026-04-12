//
//  Extensions.swift
//  becap
//
//  Created by Victor Derveaux on 24/01/2026.
//

import Foundation

extension Int {
    var convertToDate: Date {
        var comps = DateComponents()
        comps.hour = self / 60
        comps.minute = self % 60
        return Calendar.current.date(from: comps) ?? Date()
    }
}

extension Date {
    var convertToMinutes: Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: self)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }
}

extension Notification.Name {
    static let deepLinkRouterHandleExternalURL = Notification.Name("DeepLinkRouter.HandleExternalURL")
}
