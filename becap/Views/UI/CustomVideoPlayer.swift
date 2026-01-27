//
//  CustomVideoPlayer.swift
//  becap
//
//  Created by Victor Derveaux on 31/10/2025.
//

import SwiftUI
import AVKit

enum PlayerConfiguration {
    case regular
    case postPager
    case postPagerComments
    case preview
}

struct CustomVideoPlayer: UIViewRepresentable {
    let videoURL: URL
    var thumbnailURL: URL?
    var configuration: PlayerConfiguration = .regular

    func makeUIView(context: Context) -> PlayerContainerView {
        let container = PlayerContainerView(frame: UIScreen.main.bounds)
        container.configure(with: videoURL, thumbnailURL: thumbnailURL, configuration: configuration)
        configureAudioSession()
        return container
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.applyConfiguration(configuration)
    }

    func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        } catch {
            try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        }
    }
}

final class PlayerContainerView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerObserver: NSKeyValueObservation?
    private var playerItemObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var audioSessionObserver: NSObjectProtocol?

    // Subviews
    private var hostingThumbnail: UIHostingController<AnyView>?
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    private var playIcon = UIImageView(image: UIImage(systemName: "play.fill"))
    private var muteButton = UIButton(type: .system)

    private var isMuted: Bool = false
    private var isPlaying: Bool = false
    private var playWhenReady: Bool = false
    private var isReadyToPlay: Bool = false

    func configure(with url: URL, thumbnailURL: URL?, configuration: PlayerConfiguration = .regular) {
        backgroundColor = .black

        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer.insertSublayer(layer, at: 0)
        playerLayer = layer

        // Thumbnail
        if let thumbnailURL = thumbnailURL {
            let thumbnailView = AsyncCachedImage(url: thumbnailURL)
                .scaledToFill()
                .clipped()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)

            let host = UIHostingController(rootView: AnyView(thumbnailView))
            host.view.frame = bounds
            host.view.backgroundColor = .clear
            addSubview(host.view)
            hostingThumbnail = host
        }

        // Loader
        activityIndicator.color = .white
        addSubview(activityIndicator)

        // Play icon
        playIcon.tintColor = .white
        playIcon.contentMode = .scaleAspectFit
        playIcon.frame.size = CGSize(width: 60, height: 60)
        addSubview(playIcon)

        // Mute/unmute button
        muteButton.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
        muteButton.tintColor = .white
        muteButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        muteButton.layer.cornerRadius = 20
        muteButton.frame = CGRect(x: 20, y: 20, width: 40, height: 40)
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        addSubview(muteButton)

        // Observe readiness
        playerItemObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                if item.status == .readyToPlay {
                    self.player?.play()
                }
            }
        }

        // Observe controls
        playerObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            guard let self else { return }

            DispatchQueue.main.async {
                switch player.timeControlStatus {
                case .playing:
                    // We detect if the video is ready to play right after .waitingToPlayAtSpecifiedRate
                    if self.activityIndicator.isAnimating {
                        self.isReadyToPlay = true
                        self.activityIndicator.stopAnimating() // Since we stop the anim, we won't go throught here anymore
                        self.hostingThumbnail?.view.removeFromSuperview()

                        self.applyConfiguration(configuration)

                        guard self.playWhenReady else { self.player?.pause(); break }
                    }
                    self.isPlaying = true
                    self.playIcon.isHidden = true

                case .paused:
                    self.isPlaying = false
                    self.playIcon.isHidden = false

                default:
                    break
                }
            }
        }

        // Reset video to beginning on ended
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                             object: player.currentItem,
                                                             queue: .main) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.pause()
        }

        audioSessionObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification,
                                                                      object: AVAudioSession.sharedInstance(),
                                                                      queue: .main) { [weak self] notification in
            self?.handleAudioSessionInterruption(notification)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(togglePlayPause))
        addGestureRecognizer(tap)
    }

    @objc private func togglePlayPause() {
        guard let player else { return }
        isPlaying ? player.pause() : player.play()
    }

    @objc private func toggleMute() {
        guard let player else { return }

        isMuted.toggle()
        player.isMuted = isMuted
        let iconName = isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
        muteButton.setImage(UIImage(systemName: iconName), for: .normal)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = bounds
        CATransaction.commit()

        activityIndicator.center = CGPoint(x: bounds.midX, y: bounds.midY)
        playIcon.center = CGPoint(x: bounds.midX, y: bounds.midY)
        hostingThumbnail?.view.frame = bounds

        muteButton.frame.origin = CGPoint(x: bounds.width - muteButton.frame.width - 20, y: 20)
    }

    deinit {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        if let audioSessionObserver {
            NotificationCenter.default.removeObserver(audioSessionObserver)
        }
    }

    private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            player?.pause()
            isPlaying = false
            playIcon.isHidden = false

        case .ended:
            let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume), playWhenReady {
                player?.play()
            }
        @unknown default:
            break
        }
    }
}

extension PlayerContainerView {
    func applyConfiguration(_ config: PlayerConfiguration) {
        guard isReadyToPlay else {
            activityIndicator.startAnimating()
            playIcon.isHidden = true
            muteButton.isHidden = true
            return
        }

        switch config {
        case .regular:
            playWhenReady = false
            muteButton.isHidden = false

        case .postPager:
            playWhenReady = false
            muteButton.isHidden = false

        case .postPagerComments:
            muteButton.isHidden = true

        case .preview:
            playWhenReady = true
            muteButton.isHidden = false
        }
    }
}
