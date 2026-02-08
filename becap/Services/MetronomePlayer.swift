//
//  MetronomePlayer.swift
//  becap
//
//  Created by OpenAI on 2025-11-01.
//

import AVFoundation
import AudioToolbox
import Foundation
#if canImport(UIKit)
import UIKit
#endif

final class MetronomePlayer {
    private let bpm: Double
    private let soundId: SystemSoundID
    private let queue = DispatchQueue(label: "becap.metronome.queue")
    private var timer: DispatchSourceTimer?
#if canImport(UIKit)
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .rigid)
#endif

    var onBeat: (() -> Void)?

    init(bpm: Double = 60, soundId: SystemSoundID = 1104) {
        self.bpm = bpm
        self.soundId = soundId
    }

    func start() {
        stop()
        guard bpm > 0 else { return }

        let interval = 60.0 / bpm
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            self?.playBeat()
        }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func playBeat() {
        AudioServicesPlaySystemSound(soundId)
#if canImport(UIKit)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hapticGenerator.prepare()
            self.hapticGenerator.impactOccurred()
            self.onBeat?()
        }
#else
        onBeat?()
#endif
    }
}
