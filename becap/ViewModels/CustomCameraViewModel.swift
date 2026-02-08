//
//  CustomCameraViewModel.swift
//  becap
//
//  Created by Victor Derveaux on 31/10/2025.
//

import SwiftUI
import AVFoundation
import AudioToolbox

enum CameraMode: Equatable {
    case normal
    case plank
}

final class CustomCameraViewModel: NSObject, ObservableObject {
    @Published var capturedMedia: ChallengeRawMedia?
    @Published var isRecordingVideo = false
    @Published var isLockedRecording: Bool = false
    @Published private var isBackCamera: Bool = true
    @Published private var videoRecordingElapsedTime: TimeInterval = 0
    @Published private var videoRecordingRemainingTime: TimeInterval = 0
    @Published private var isFlashOn = false

    var showFlashButton: Bool {
        !isRecordingVideo && isBackCamera
    }

    var flashIconName: String {
        isFlashOn ? "bolt.fill" : "bolt.slash.fill"
    }

    var lockIconName: String {
        isLockedRecording ? "lock.fill" : "lock.open.fill"
    }

    var videoRecordingTimer: String {
        let timeValue = mode == .plank ? videoRecordingRemainingTime : videoRecordingElapsedTime
        let minutes = Int(timeValue) / 60
        let seconds = Int(timeValue) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var videoTimer: Timer?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentCameraPosition: AVCaptureDevice.Position = .back {
        didSet {
            isBackCamera = currentCameraPosition == .back ? true : false
        }
    }

    private let captureSession = AVCaptureSession()
    private let outputPhoto = AVCapturePhotoOutput()
    private let outputMovie = AVCaptureMovieFileOutput()
    private let captureSessionQueueLabel: String = "camera.session.queue"
    private let mode: CameraMode
    private let plankDuration: TimeInterval
    private let plankPreparationDuration: TimeInterval = 5
    private let plankFrameRate: Double = 5
    private let defaultFrameRate: Double = 30

    init(mode: CameraMode = .normal, plankDuration: TimeInterval = 120) {
        self.mode = mode
        self.plankDuration = plankDuration
        super.init()
        configureCaptureSession()
    }

    deinit {
        videoTimer?.invalidate()
        stopCaptureSession()
    }

    func startCaptureSession() {
        DispatchQueue(label: captureSessionQueueLabel).async {
            guard !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }

    func stopCaptureSession() {
        DispatchQueue(label: captureSessionQueueLabel).async {
            guard self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }

    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        if let previewLayer {
            return previewLayer
        }

        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        previewLayer = layer
        return layer
    }

    func onCaptureButtonTap() {
        if isRecordingVideo {
            stopVideoRecording()
            isLockedRecording = false
        } else {
            capturePhoto()
        }
    }

    func manageLongPress(drag: DragGesture.Value? = nil) {
        if !isRecordingVideo { // Long press done and not recording -> starts video recording
            startVideoRecording()
        } else if let drag { // Is in long press and drag not nil -> locking recording following translation
            guard -drag.translation.width > 70 else { return }

            isLockedRecording = true
        } else if !isLockedRecording { // Is in long press with recording not locked and no drag, means there was a chaging state triggered by .onEnded -> long press is done, we stop the recording
            stopVideoRecording()
        }
    }

    func retakeMedia() {
        capturedMedia = nil
    }

    func switchCamera() {
        guard !isRecordingVideo else { return }
        updateCameraCaptureSession()
    }

    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }

        try? device.lockForConfiguration()
        device.torchMode = isFlashOn ? .off : .on
        isFlashOn.toggle()
        device.unlockForConfiguration()
    }

    func setZoom(scale: CGFloat) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        try? device.lockForConfiguration()
        let zoom = max(1.0, min(scale, device.activeFormat.videoMaxZoomFactor))
        device.videoZoomFactor = zoom
        device.unlockForConfiguration()
    }

    // Privates

    private func configureCaptureSession() {
        DispatchQueue(label: captureSessionQueueLabel).async {
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high

            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.captureSession.canAddInput(videoInput) else { return }
            self.captureSession.addInput(videoInput)


            if self.shouldCaptureAudio(),
               let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               self.captureSession.canAddInput(audioInput) {
                self.captureSession.addInput(audioInput)
            }

            if self.captureSession.canAddOutput(self.outputPhoto) {
                self.captureSession.addOutput(self.outputPhoto)
            }

            if self.captureSession.canAddOutput(self.outputMovie) {
                self.captureSession.addOutput(self.outputMovie)
            }

            if let device = AVCaptureDevice.default(for: .video) {
                try? device.lockForConfiguration()
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
                device.unlockForConfiguration()
            }

            self.captureSession.commitConfiguration()
            self.startCaptureSession()
        }
    }

    private func updateCameraCaptureSession() {
        DispatchQueue(label: captureSessionQueueLabel).async {
            self.captureSession.beginConfiguration()

            for input in self.captureSession.inputs.compactMap({ $0 as? AVCaptureDeviceInput }) {
                if input.device.hasMediaType(.video) {
                    self.captureSession.removeInput(input)
                }
            }

            let newCameraPosition: AVCaptureDevice.Position = (self.currentCameraPosition == .back) ? .front : .back

            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newCameraPosition),
                  let newDeviceInput = try? AVCaptureDeviceInput(device: newDevice),
                  self.captureSession.canAddInput(newDeviceInput) else { return }

            self.captureSession.addInput(newDeviceInput)
            self.captureSession.commitConfiguration()
            self.currentCameraPosition = newCameraPosition
        }
    }

    private func shouldCaptureAudio() -> Bool {
        let session = AVAudioSession.sharedInstance()
        if session.category == .playAndRecord || session.mode == .voiceChat || session.mode == .videoChat {
            return false
        }
        return true
    }

    private func capturePhoto() {
        guard !isRecordingVideo else { return } // évite de capturer pendant un enregistrement

        let settings = AVCapturePhotoSettings()
        if let device = AVCaptureDevice.default(for: .video), device.hasFlash {
            settings.flashMode = isFlashOn ? .on : .off
        }
        outputPhoto.capturePhoto(with: settings, delegate: self)
    }

    private func startVideoRecording() {
        guard !outputMovie.isRecording else { return }
        if mode == .plank {
            updateActiveFrameRate(targetFrameRate: plankFrameRate)
        } else {
            updateActiveFrameRate(targetFrameRate: defaultFrameRate)
        }

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        outputMovie.startRecording(to: tempURL, recordingDelegate: self)
        startRecordingTimer()
        isRecordingVideo = true
    }

    private func stopVideoRecording() {
        guard outputMovie.isRecording else { return }

        outputMovie.stopRecording()
        isRecordingVideo = false
        updateActiveFrameRate(targetFrameRate: defaultFrameRate)
        stopRecordingTimer()
        isLockedRecording = false
    }

    private func startRecordingTimer() {
        let recordingStartTime = Date()
        videoRecordingElapsedTime = 0
        if mode == .plank {
            videoRecordingRemainingTime = plankDuration + plankPreparationDuration
        } else {
            videoRecordingRemainingTime = 0
        }
        videoTimer?.invalidate()
        videoTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.mode == .plank {
                self.videoRecordingRemainingTime = max(self.videoRecordingRemainingTime - 1, 0)

                let prepRemaining = max(self.videoRecordingRemainingTime - self.plankDuration, 0)
                if prepRemaining > 0 {
                    AudioServicesPlaySystemSound(1057)
                } else if self.videoRecordingRemainingTime <= 0 {
                    self.stopVideoRecording()
                }
            } else {
                self.videoRecordingElapsedTime = Date().timeIntervalSince(recordingStartTime)
            }
        }
    }

    private func stopRecordingTimer() {
        videoTimer?.invalidate()
        videoTimer = nil
        videoRecordingElapsedTime = 0
        videoRecordingRemainingTime = 0
    }
}

// MARK: - AVCapture Delegates

extension CustomCameraViewModel: AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(),
           let image = UIImage(data: data) {
            DispatchQueue.main.async {
                self.capturedMedia = .image(image)
            }
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                print("❌ Erreur enregistrement vidéo :", error)
            }
            return
        }

        DispatchQueue.main.async {
            self.capturedMedia = .video(ChallengeRawMedia.VideoRawData(url: outputFileURL, thumbnailImage: nil))
        }

        generateThumbnailAsync(for: outputFileURL) { [weak self] thumbnail in
            guard let self else { return }
            DispatchQueue.main.async {
                self.capturedMedia = .video(ChallengeRawMedia.VideoRawData(url: outputFileURL,
                                                                           thumbnailImage: thumbnail))
            }
        }
    }

    private func generateThumbnail(for url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero

        let time = CMTime(seconds: 0.1, preferredTimescale: 600)

        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("❌ Impossible de générer la miniature vidéo :", error)
            return nil
        }
    }

    private func generateThumbnailAsync(for url: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = self.generateThumbnail(for: url)
            completion(thumbnail)
        }
    }

    private func updateActiveFrameRate(targetFrameRate: Double) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        do {
            try device.lockForConfiguration()
            if let range = device.activeFormat.videoSupportedFrameRateRanges.first {
                let clampedFPS = min(max(targetFrameRate, range.minFrameRate), range.maxFrameRate)
                let frameDuration = CMTime(value: 1, timescale: CMTimeScale(clampedFPS))
                device.activeVideoMinFrameDuration = frameDuration
                device.activeVideoMaxFrameDuration = frameDuration
                print("✅ Framerate fixé à \(String(format: "%.2f", clampedFPS)) fps")
            }
            device.unlockForConfiguration()
        } catch {
            print("❌ Impossible de configurer le framerate :", error)
        }
    }
}
