//
//  ChallengeCaptureMode.swift
//  becap
//
//  Created by OpenAI on 2025-11-01.
//

import Foundation

enum ChallengeCaptureMode: Equatable {
    case normal
    case plank(duration: TimeInterval = 120)
    case pushUps(target: Int, bpm: Double = 60)

    var isPlank: Bool {
        if case .plank = self { return true }
        return false
    }

    var isPushUps: Bool {
        if case .pushUps = self { return true }
        return false
    }

    var plankDuration: TimeInterval? {
        if case let .plank(duration) = self { return duration }
        return nil
    }

    var pushUpsTarget: Int? {
        if case let .pushUps(target, _) = self { return target }
        return nil
    }

    var pushUpsBpm: Double? {
        if case let .pushUps(_, bpm) = self { return bpm }
        return nil
    }
}
