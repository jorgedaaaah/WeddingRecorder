//
//  CameraService.swift
//  WeddingRecorder
//
//  Created by Jorge on 8/2/25.
//

import AVFoundation
import SwiftUI

enum PhotoCaptureState: Equatable {
    case idle
    case countdown(Int)
    case displayingPhoto(UIImage)
    case showingBurstAnimation([UIImage]) // New state for final animation
    
    // Equatable conformance for UIImage comparison (by reference or contents)
    static func == (lhs: PhotoCaptureState, rhs: PhotoCaptureState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.countdown(let lVal), .countdown(let rVal)): return lVal == rVal
        case (.displayingPhoto(let lImg), .displayingPhoto(let rImg)): return lImg === rImg // Compare UIImage by reference
        case (.showingBurstAnimation(let lImages), .showingBurstAnimation(let rImages)): return lImages.elementsEqual(rImages, by: { $0 === $1 }) // Compare UIImage arrays by reference
        default: return false
        }
    }
}

class CameraService: NSObject, ObservableObject {
    
    // MARK: - Properties
    let session = AVCaptureSession()
    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var isSessionConfigured = false
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var photoCaptureState: PhotoCaptureState = .idle
    
    private var capturedBurstImages: [UIImage] = [] // New array to store burst photos
    private var videoOutput = AVCaptureMovieFileOutput()
    private var photoOutput: AVCapturePhotoOutput?
    private var currentVideoURL: URL?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var setupAttempted = false
    
    // Session queue to prevent main thread blocking
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    // Completion handler for recording
    var recordingCompleted: ((URL?) -> Void)?
    // var photoCaptureCompletionHandler: ((_ photo: UIImage?) -> Void)? // No longer needed
    private var currentPhotoCaptureContinuation: CheckedContinuation<UIImage?, Error>?
    
    // MARK: - Setup
    override init() {
        super.init()
        checkAuthorization()
    }
    
    // MARK: - Photo Capture
    func takePhoto() async throws -> UIImage? {
        #if targetEnvironment(simulator)
        print("📸 Simulating photo capture...")
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        // Provide a placeholder image for simulator
        return UIImage(systemName: "photo")
        #else
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self,
                      let photoOutput = self.photoOutput else {
                    print("❌ Photo output not available")
                    continuation.resume(throwing: PhotoCaptureError.outputNotAvailable)
                    return
                }

                self.currentPhotoCaptureContinuation = continuation

                var photoSettings = AVCapturePhotoSettings()
                if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                }
                
                photoSettings.flashMode = .auto
                // We enable high-resolution photo capture in photoSettings.
                // The AVCapturePhotoOutput itself must be configured to support this.
                // This is managed by setting maxPhotoDimensions for the output (see performSessionSetup)
                photoSettings.isHighResolutionPhotoEnabled = true


                if let photoCaptureConnection = photoOutput.connection(with: .video) {
                    if #available(iOS 17.0, *) {
                        if photoCaptureConnection.isVideoRotationAngleSupported(90) {
                            photoCaptureConnection.videoRotationAngle = 90
                        }
                    } else {
                        if photoCaptureConnection.isVideoOrientationSupported {
                            photoCaptureConnection.videoOrientation = .landscapeRight
                        }
                    }
                    if photoCaptureConnection.isVideoMirroringSupported {
                        photoCaptureConnection.automaticallyAdjustsVideoMirroring = false
                        photoCaptureConnection.isVideoMirrored = true
                    }
                }

                photoOutput.capturePhoto(with: photoSettings, delegate: self)
                print("📸 Capture photo initiated...")
            }
        }
        #endif
    }
    
    private enum PhotoCaptureError: Error {
        case outputNotAvailable
        case captureFailed(Error)
        case imageDataMissing
    }
    
    // MARK: - Photo Capture Burst
    func takePhotoBurst() async {
        for i in 1...3 {
            let countdownSeconds = Settings.shared.photoBurstCountdownDuration.rawValue
            // Countdown before each photo, using the user-defined setting
            for count in (1...countdownSeconds).reversed() {
                DispatchQueue.main.async {
                    self.photoCaptureState = .countdown(count)
                }
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                } catch {
                    print("❌ Error during photo countdown: \(error)")
                    DispatchQueue.main.async {
                        self.photoCaptureState = .idle
                    }
                    return
                }
            }
            
            print("📸 Taking photo \(i) of 3...")
            do {
                let capturedImage = try await takePhoto()
                if let image = capturedImage {
                    // Temporarily display the photo
                    DispatchQueue.main.async {
                        self.photoCaptureState = .displayingPhoto(image)
                    }
                    do {
                        try await Task.sleep(nanoseconds: 2_000_000_000) // Display photo for 2 seconds
                    } catch {
                        print("❌ Error displaying photo: \(error)")
                    }
                    
                    // Store image for final animation
                    self.capturedBurstImages.append(image)
                }
            } catch {
                print("❌ Error taking photo \(i): \(error)")
            }
            
            // Only add delay if not the last photo and not showing the final animation yet
            if i < 3 {
                // Delay before next photo burst cycle starts
                do {
                    try await Task.sleep(nanoseconds: 3_000_000_000) // Wait 3 seconds before next countdown
                } catch {
                    print("❌ Error waiting for next photo burst: \(error)")
                }
            }
        } // End of for loop
        
        print("✅ Photo burst completed. Showing final animation...")
        
        // After all photos are taken, show the burst animation
        if !capturedBurstImages.isEmpty {
            DispatchQueue.main.async {
                self.photoCaptureState = .showingBurstAnimation(self.capturedBurstImages)
            }
            do {
                try await Task.sleep(nanoseconds: 33_000_000_000) // Display animation for 33 seconds
            } catch {
                print("❌ Error displaying burst animation: \(error)")
            }
        }
        
        // Ensure state is idle and clear images at the very end
        DispatchQueue.main.async {
            self.photoCaptureState = .idle
            self.capturedBurstImages.removeAll() // Clear images after animation
        }
    }
    
    // MARK: - Authorization
    func checkAuthorization() {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        DispatchQueue.main.async {
            self.authorizationStatus = currentStatus
        }
        
        print("📱 Current camera authorization status: \(currentStatus.description)")
        
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            self.isAuthorized = true
            print("🖥️ Simulator: Setting authorized to true")
            self.setupSessionIfNeeded()
        }
        print("🖥️ Running in simulator - camera simulation enabled")
        #else
        switch currentStatus {
        case .authorized:
            DispatchQueue.main.async {
                self.isAuthorized = true
                print("✅ Camera already authorized")
                self.setupSessionIfNeeded()
            }
            
        case .notDetermined:
            print("❓ Camera permission not determined - requesting access...")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                print("📱 Camera permission result: \(granted)")
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    self?.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    if granted {
                        print("✅ Camera access granted - setting up session")
                        self?.setupSessionIfNeeded()
                    } else {
                        print("❌ Camera access denied")
                    }
                }
            }
            
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isAuthorized = false
                print("❌ Camera access denied or restricted")
            }
            
        @unknown default:
            DispatchQueue.main.async {
                self.isAuthorized = false
                print("❌ Unknown camera authorization status")
            }
        }
        #endif
    }
    
    // MARK: - Session Setup - FIXED TO PREVENT HANGS
    private func setupSessionIfNeeded() {
        guard isAuthorized else {
            print("❌ Cannot setup session - not authorized")
            return
        }
        
        guard !setupAttempted else {
            print("⚠️ Session setup already attempted")
            return
        }
        
        setupAttempted = true
        print("🔧 Starting session setup...")
        
        // ALL session configuration on dedicated queue
        sessionQueue.async { [weak self] in
            self?.performSessionSetup()
        }
    }
    
    private func performSessionSetup() {
        session.beginConfiguration()
        print("🔧 Session configuration started")

        // CRITICAL: Stop any existing session first
        if session.isRunning {
            session.stopRunning()
            print("🛑 Stopped existing session")
        }

        // Set session preset
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
            print("✅ Session preset set to high")
        }

        // Add video input (front camera for wedding app)
        if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            do {
                // CRITICAL: Release any existing input first
                if let existingVideoInput = self.videoInput {
                    session.removeInput(existingVideoInput)
                    print("🔄 Removed existing video input")
                }
                
                let videoInput = try AVCaptureDeviceInput(device: frontCamera)
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                    self.videoInput = videoInput
                    print("✅ Front camera video input added")
                } else {
                    print("❌ Cannot add video input to session")
                }
            } catch {
                print("❌ Failed to create video input: \(error.localizedDescription)")
            }
        } else {
            print("❌ Front camera not available")
        }

        // Add audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            do {
                // CRITICAL: Release any existing audio input first
                if let existingAudioInput = self.audioInput {
                    session.removeInput(existingAudioInput)
                    print("🔄 Removed existing audio input")
                }
                
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                    self.audioInput = audioInput
                    print("✅ Audio input added")
                } else {
                    print("❌ Cannot add audio input to session")
                }
            } catch {
                print("❌ Failed to create audio input: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ Audio device not available")
        }

        // Add video output - CLEAN FIRST
        if session.outputs.contains(videoOutput) {
            session.removeOutput(videoOutput)
            print("🔄 Removed existing video output")
        }
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            print("✅ Video output added")
        } else {
            print("❌ Cannot add video output to session")
        }
        
        // Add photo output
        if let existingPhotoOutput = photoOutput {
            session.removeOutput(existingPhotoOutput)
            self.photoOutput = nil
            print("🔄 Removed existing photo output")
        }
        
        let photoOutput = AVCapturePhotoOutput()
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            self.photoOutput = photoOutput
            
            // Configure for maximum resolution from the video device
            if let videoDevice = self.videoInput?.device {
                let supportedDimensions = videoDevice.activeFormat.supportedMaxPhotoDimensions
                var largestDimension = CMVideoDimensions(width: 0, height: 0)
                var largestArea: Int32 = 0
                
                for dimension in supportedDimensions {
                    let area = dimension.width * dimension.height
                    if area > largestArea {
                        largestArea = area
                        largestDimension = dimension
                    }
                }
                
                photoOutput.maxPhotoDimensions = largestDimension
                print("✅ Photo output added with max dimensions: \(largestDimension.width)x\(largestDimension.height)")
            } else {
                print("⚠️ Photo output added but could not set max dimensions")
            }
        } else {
            print("❌ Cannot add photo output to session")
        }

        session.commitConfiguration()
        print("✅ Session configuration complete")
        
        // Update state on main thread
        DispatchQueue.main.async { [weak self] in
            self?.isSessionConfigured = true
            // Don't auto-start here - let ContentView control when to start
        }
    }
    
    // MARK: - Session Control - SIMPLIFIED AND SAFE
    func startSession() {
        guard isAuthorized else {
            print("❌ Cannot start session - not authorized")
            return
        }
        
        guard isSessionConfigured else {
            print("❌ Cannot start session - not configured")
            setupSessionIfNeeded()
            return
        }
        
        guard !isSessionRunning else {
            print("⚠️ Session already running")
            return
        }
        
        print("🚀 Starting camera session...")
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.startRunning()
            
            DispatchQueue.main.async {
                let isRunning = self.session.isRunning
                self.isSessionRunning = isRunning
                print("📹 Camera session running: \(isRunning)")
            }
        }
    }
    
    func stopSession() {
        guard isSessionRunning else {
            print("⚠️ Session not running")
            return
        }
        
        print("🛑 Stopping camera session...")
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Stop recording first if active
            if self.videoOutput.isRecording {
                self.videoOutput.stopRecording()
            }
            
            self.session.stopRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = false
                print("📹 Camera session stopped")
            }
        }
    }
    
    // MARK: - Recording Control - SIMPLIFIED AND ROBUST
    func startRecording() {
        #if targetEnvironment(simulator)
        print("🎬 Simulating recording start...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.recordingCompleted?(nil)
        }
        return
        #else
        print("🎬 Attempting to start recording...")

        guard isAuthorized && isSessionConfigured && isSessionRunning else {
            print("❌ Cannot record - session not ready")
            DispatchQueue.main.async {
                self.recordingCompleted?(nil)
            }
            return
        }

        guard !videoOutput.isRecording else {
            print("⚠️ Already recording")
            return
        }

        if let availableSpace = getAvailableDiskSpace() {
            print("💾 Available disk space: \(availableSpace / 1024 / 1024) MB")
            if availableSpace < 100 * 1024 * 1024 {
                print("❌ Insufficient disk space")
                DispatchQueue.main.async {
                    self.recordingCompleted?(nil)
                }
                return
            }
        }

        let tempDir = FileManager.default.temporaryDirectory
        let videoURL = tempDir.appendingPathComponent("wedding_video_\(UUID().uuidString).mov")
        currentVideoURL = videoURL

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
            print("📁 Temporary directory verified: \(tempDir)")
        } catch {
            print("❌ Failed to create temp directory: \(error)")
            DispatchQueue.main.async {
                self.recordingCompleted?(nil)
            }
            return
        }

        // ⚠️ Move configuration and start to sessionQueue
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            guard let connection = self.videoOutput.connection(with: .video) else {
                print("❌ No video connection available")
                DispatchQueue.main.async {
                    self.recordingCompleted?(nil)
                }
                return
            }

            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            } else {
                if let connection = videoOutput.connection(with: .video),
                   connection.isVideoOrientationSupported {
                    connection.videoOrientation = .landscapeRight
                }
            }

            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }

            print("🎬 Scheduling recording after delay...")

            // 🔁 DEFER actual recording start slightly to give AVFoundation time
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                print("🎬 Starting recording to: \(videoURL)")
                self.videoOutput.startRecording(to: videoURL, recordingDelegate: self)
            }
        }
        #endif
    }
    
    private func getAvailableDiskSpace() -> Int64? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let dictionary = try? FileManager.default.attributesOfFileSystem(forPath: paths.last!) {
            if let freeBytes = dictionary[.systemFreeSize] as? Int64 {
                return freeBytes
            }
        }
        return nil
    }
    
    func stopRecording() {
        #if targetEnvironment(simulator)
        print("🛑 Simulating recording stop...")
        recordingCompleted?(nil)
        #else
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.videoOutput.isRecording {
                print("🛑 Stopping recording...")
                self.videoOutput.stopRecording()
            } else {
                print("⚠️ Not currently recording")
            }
        }
        #endif
    }
    
    // MARK: - Public method to force refresh authorization
    func refreshAuthorization() {
        setupAttempted = false
        isSessionConfigured = false
        checkAuthorization()
    }
    
    // MARK: - Cleanup
    deinit {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraService: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput,
                   didStartRecordingTo fileURL: URL,
                   from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async {
            print("✅ Recording started successfully to: \(fileURL)")
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput,
                   didFinishRecordingTo outputFileURL: URL,
                   from connections: [AVCaptureConnection],
                   error: Error?) {
        
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                let nsError = error as NSError
                print("❌ Recording failed: \(error.localizedDescription)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Full error: \(nsError)")
                
                // Check if it was actually successful despite the error
                if let userInfo = nsError.userInfo as? [String: Any],
                   let success = userInfo["AVErrorRecordingSuccessfullyFinishedKey"] as? Bool,
                   success {
                    print("✅ Recording actually completed successfully despite error message")
                    self?.recordingCompleted?(outputFileURL)
                } else {
                    self?.recordingCompleted?(nil)
                }
            } else {
                print("✅ Recording completed successfully: \(outputFileURL)")
                self?.recordingCompleted?(outputFileURL)
            }
            
            self?.currentVideoURL = nil
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { self.currentPhotoCaptureContinuation = nil }
        
        if let error = error {
            print("❌ Error capturing photo: \(error.localizedDescription)")
            currentPhotoCaptureContinuation?.resume(throwing: PhotoCaptureError.captureFailed(error))
            return
        }
        
        guard let photoData = photo.fileDataRepresentation(),
              let cgImage = UIImage(data: photoData)?.cgImage else {
            print("❌ Could not get image data from photo")
            currentPhotoCaptureContinuation?.resume(throwing: PhotoCaptureError.imageDataMissing)
            return
        }
        
        let orientation = imageOrientation(from: photo.metadata)
        var image = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
        
        // Rotate image physically if needed to ensure correct display in SwiftUI Image view
        // The goal is to have the UIImage itself be .up orientation for consistent display
        if orientation != .up {
            image = rotateImage(image, orientation: orientation)
        }
        
        // Save photo to photo library
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        print("✅ Photo captured and saved to library.")
        
        currentPhotoCaptureContinuation?.resume(returning: image)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // Called when photo will be captured
        // Can play a shutter sound here
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // Called when photo has been captured
    }
    
    // Helper function to convert CGImagePropertyOrientation to UIImage.Orientation
    private func imageOrientation(from metadata: [String : Any]) -> UIImage.Orientation {
        guard let orientationValue = metadata[String(kCGImagePropertyOrientation)] as? UInt32,
              let cgOrientation = CGImagePropertyOrientation(rawValue: orientationValue) else {
            return .up
        }
        
        switch cgOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
    
    // Helper function to physically rotate UIImage
    private func rotateImage(_ image: UIImage, orientation: UIImage.Orientation) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let rotatedSize: CGSize
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            rotatedSize = CGSize(width: image.size.height, height: image.size.width)
        default:
            rotatedSize = image.size
        }

        let renderer = UIGraphicsImageRenderer(size: rotatedSize, format: image.imageRendererFormat)

        let rotatedImage = renderer.image { context in
            let transform = self.transform(for: image, orientation: orientation, rotatedSize: rotatedSize)
            context.cgContext.concatenate(transform)
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }

        return rotatedImage
    }

    // Helper function to calculate the CGAffineTransform for image rotation
    private func transform(for image: UIImage, orientation: UIImage.Orientation, rotatedSize: CGSize) -> CGAffineTransform {
        var transform = CGAffineTransform.identity

        switch orientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: rotatedSize.width, y: rotatedSize.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: rotatedSize.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: rotatedSize.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }

        switch orientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: rotatedSize.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: rotatedSize.height, y: 0) // Note: width/height swapped for vertical flip
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        return transform
    }
}

// MARK: - Helper Extension for AVAuthorizationStatus
extension AVAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorized: return "authorized"
        @unknown default: return "unknown"
        }
    }
}
