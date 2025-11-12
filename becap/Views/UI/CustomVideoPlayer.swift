//
//  CustomVideoPlayer.swift
//  becap
//
//  Created by Victor Derveaux on 31/10/2025.
//

import SwiftUI
import AVKit

struct CustomVideoPlayer: UIViewRepresentable {
    let videoURL: URL
    var thumbnailURL: URL?

    func makeUIView(context: Context) -> UIView {
        let container = PlayerContainerView(frame: UIScreen.main.bounds)
        container.configure(with: videoURL, thumbnailURL: thumbnailURL)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

final class PlayerContainerView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var hostingThumbnail: UIHostingController<AnyView>?
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    private var playIcon = UIImageView(image: UIImage(systemName: "play.fill"))
    private var muteButton = UIButton(type: .system)
    private var isMuted = false
    private var isPlaying = false
    private var observer: NSKeyValueObservation?

    func configure(with url: URL, thumbnailURL: URL?) {
        backgroundColor = .black

        // Player setup
        let player = AVPlayer(url: url)
        self.player = player

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer.insertSublayer(layer, at: 0)
        playerLayer = layer

        // ✅ Thumbnail avec AsyncCachedImage
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

        // Loader centré
        activityIndicator.color = .white
        addSubview(activityIndicator)
        activityIndicator.startAnimating()

        // Play icon centré
        playIcon.tintColor = .white
        playIcon.contentMode = .scaleAspectFit
        playIcon.frame.size = CGSize(width: 60, height: 60)
        playIcon.isHidden = true
        addSubview(playIcon)

        // 🔇 Bouton Mute / Unmute
        muteButton.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
        muteButton.tintColor = .white
        muteButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        muteButton.layer.cornerRadius = 20
        muteButton.frame = CGRect(x: 20, y: 20, width: 40, height: 40)
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        addSubview(muteButton)

        // Observe readiness
        observer = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                if player.timeControlStatus == .playing {
                    self.activityIndicator.removeFromSuperview()
                    self.hostingThumbnail?.view.removeFromSuperview()
                    self.isPlaying = true
                    self.playIcon.isHidden = true
                } else if player.timeControlStatus == .paused {
                    self.isPlaying = false
                    self.playIcon.isHidden = false
                }
            }
        }

        // Lecture et gestures
        player.play()

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem,
                                               queue: .main) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.pause()
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
        playerLayer?.frame = bounds
        activityIndicator.center = CGPoint(x: bounds.midX, y: bounds.midY)
        playIcon.center = CGPoint(x: bounds.midX, y: bounds.midY)
        hostingThumbnail?.view.frame = bounds

        muteButton.frame.origin = CGPoint(x: bounds.width - muteButton.frame.width - 20, y: 20)
    }
}
