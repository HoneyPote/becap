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
    @Published var isProcessingTimelapse = false

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
    private let outputVideoData = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "camera.video.data.queue")
    private let captureSessionQueueLabel: String = "camera.session.queue"
    private let mode: CameraMode
    private let plankDuration: TimeInterval
    private let plankPreparationDuration: TimeInterval = 5
    private var currentProcessId = UUID()
    private var timelapseOutputURL: URL?
    private var timelapseStartTime: CMTime?
    private var timelapseSpeedMultiplier: Double = 1.0
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var assetWriterAdaptor: AVAssetWriterInputPixelBufferAdaptor?

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
        currentProcessId = UUID()
        capturedMedia = nil
        isProcessingTimelapse = false
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

            if self.captureSession.canAddOutput(self.outputVideoData) {
                self.outputVideoData.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                self.outputVideoData.setSampleBufferDelegate(self, queue: self.videoDataOutputQueue)
                self.captureSession.addOutput(self.outputVideoData)
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
        if mode == .plank {
            startTimelapseRecording()
            return
        }

        guard !outputMovie.isRecording else { return }

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        outputMovie.startRecording(to: tempURL, recordingDelegate: self)
        startRecordingTimer()
        isRecordingVideo = true
    }

    private func stopVideoRecording() {
        if mode == .plank {
            stopTimelapseRecording()
            return
        }

        guard outputMovie.isRecording else { return }

        outputMovie.stopRecording()
        isRecordingVideo = false
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
                } else if self.videoRecordingRemainingTime > 0, self.videoRecordingRemainingTime <= 5 {
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

    private func startTimelapseRecording() {
        guard !isRecordingVideo else { return }

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        timelapseOutputURL = tempURL
        timelapseStartTime = nil
        timelapseSpeedMultiplier = clampedSpeedMultiplier(for: plankDuration + plankPreparationDuration)
        assetWriter = nil
        assetWriterInput = nil
        assetWriterAdaptor = nil

        startRecordingTimer()
        isRecordingVideo = true
        isProcessingTimelapse = false
    }

    private func stopTimelapseRecording() {
        guard isRecordingVideo else { return }

        isRecordingVideo = false
        stopRecordingTimer()
        isLockedRecording = false

        guard let assetWriter else { return }

        assetWriterInput?.markAsFinished()
        assetWriter.finishWriting { [weak self] in
            guard let self else { return }
            guard assetWriter.status == .completed, let outputURL = self.timelapseOutputURL else {
                print("❌ Échec export timelapse direct :", assetWriter.error as Any)
                return
            }
            self.finalizeTimelapseOutput(url: outputURL)
        }
    }
}

// MARK: - AVCapture Delegates

extension CustomCameraViewModel: AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(),
           let image = UIImage(data: data) {
            DispatchQueue.main.async {
                self.capturedMedia = .image(image)
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard mode == .plank, isRecordingVideo else { return }
        guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        if assetWriter == nil {
            guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
                  let outputURL = timelapseOutputURL else {
                return
            }

            let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            let outputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(dimensions.width),
                AVVideoHeightKey: Int(dimensions.height)
            ]

            do {
                let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
                let input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
                input.expectsMediaDataInRealTime = true
                let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)

                guard writer.canAdd(input) else {
                    print("❌ Impossible d'ajouter l'input timelapse")
                    return
                }

                writer.add(input)
                writer.startWriting()
                writer.startSession(atSourceTime: .zero)
                assetWriter = writer
                assetWriterInput = input
                assetWriterAdaptor = adaptor
                timelapseStartTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            } catch {
                print("❌ Impossible de démarrer l'écriture timelapse :", error)
                return
            }
        }

        guard let assetWriter,
              let assetWriterInput,
              let assetWriterAdaptor,
              assetWriter.status == .writing,
              assetWriterInput.isReadyForMoreMediaData,
              let timelapseStartTime else { return }

        let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let relativeTime = CMTimeSubtract(sampleTime, timelapseStartTime)
        let scaledTime = CMTimeMultiplyByFloat64(relativeTime, multiplier: 1.0 / timelapseSpeedMultiplier)
        assetWriterAdaptor.append(pixelBuffer, withPresentationTime: scaledTime)
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                print("❌ Erreur enregistrement vidéo :", error)
                self.isProcessingTimelapse = false
            }
            return
        }

        let processId = UUID()
        currentProcessId = processId

        if mode == .plank {
            return
        } else {
            DispatchQueue.main.async {
                self.capturedMedia = .video(ChallengeRawMedia.VideoRawData(url: outputFileURL, thumbnailImage: nil))
            }
            finalizeVideoOutput(originalURL: outputFileURL,
                                timelapseURL: nil,
                                processId: processId)
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

    private func createTimelapse(from url: URL,
                                 completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: url)
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }

        let durationSeconds = asset.duration.seconds
        let speedMultiplier = clampedSpeedMultiplier(for: durationSeconds)
        print("✅ Timelapse speed x\(String(format: "%.2f", speedMultiplier)) (duration \(String(format: "%.2f", durationSeconds))s)")

        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video,
                                                                      preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(nil)
            return
        }

        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform

            let scaledDuration = CMTimeMultiplyByFloat64(asset.duration, multiplier: 1.0 / speedMultiplier)
            composition.scaleTimeRange(timeRange, toDuration: scaledDuration)
        } catch {
            print("❌ Impossible de créer le timelapse :", error)
            completion(nil)
            return
        }

        guard let exportSession = AVAssetExportSession(asset: composition,
                                                      presetName: AVAssetExportPreset1280x720) else {
            completion(nil)
            return
        }

        let supportedTypes = exportSession.supportedFileTypes
        let outputFileType: AVFileType
        let outputExtension: String
        if supportedTypes.contains(.mp4) {
            outputFileType = .mp4
            outputExtension = "mp4"
        } else {
            outputFileType = .mov
            outputExtension = "mov"
            print("⚠️ Export mp4 indisponible, fallback en .mov")
        }

        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(outputExtension)

        exportSession.outputURL = outputURL
        exportSession.outputFileType = outputFileType
        exportSession.shouldOptimizeForNetworkUse = true

        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(outputURL)
            case .failed, .cancelled:
                if let error = exportSession.error {
                    print("❌ Échec export timelapse :", error)
                }
                completion(nil)
            default:
                completion(nil)
            }
        }
    }

    private func finalizeVideoOutput(originalURL: URL,
                                     timelapseURL: URL?,
                                     processId: UUID) {
        let finalURL = timelapseURL ?? originalURL
        DispatchQueue.main.async {
            if self.currentProcessId == processId {
                self.isProcessingTimelapse = false
                self.capturedMedia = .video(ChallengeRawMedia.VideoRawData(url: finalURL, thumbnailImage: nil))
            }
        }

        generateThumbnailAsync(for: finalURL) { [weak self] thumbnail in
            guard let self else { return }
            guard self.currentProcessId == processId else {
                print("⚠️ Timelapse ignoré (processId invalide)")
                return
            }

            if let timelapseURL, timelapseURL != originalURL {
                self.removeTemporaryFile(at: originalURL)
            }

            DispatchQueue.main.async {
                self.capturedMedia = .video(ChallengeRawMedia.VideoRawData(url: finalURL,
                                                                           thumbnailImage: thumbnail))
            }
        }
    }

    private func finalizeTimelapseOutput(url: URL) {
        DispatchQueue.main.async {
            self.capturedMedia = .video(ChallengeRawMedia.VideoRawData(url: url, thumbnailImage: nil))
        }

        generateThumbnailAsync(for: url) { [weak self] thumbnail in
            guard let self else { return }
            DispatchQueue.main.async {
                self.capturedMedia = .video(ChallengeRawMedia.VideoRawData(url: url,
                                                                           thumbnailImage: thumbnail))
            }
        }
    }

    private func clampedSpeedMultiplier(for durationSeconds: Double) -> Double {
        guard durationSeconds.isFinite, durationSeconds > 0 else {
            return 3.0
        }
        let target = durationSeconds / 10.0
        return min(max(target, 3.0), 12.0)
    }

    private func removeTemporaryFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("⚠️ Impossible de supprimer le fichier temporaire :", error)
        }
    }
}
