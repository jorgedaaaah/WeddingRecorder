//
//  CameraService.swift
//  WeddingRecorder
//
//  Created by Jorge on 8/2/25.
//

import AVFoundation
import SwiftUI

class CameraService: NSObject, ObservableObject {
    
    // MARK: - Properties
    let session = AVCaptureSession()
    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var isSessionConfigured = false
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    
    private var videoOutput = AVCaptureMovieFileOutput()
    private var currentVideoURL: URL?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var setupAttempted = false
    
    // Session queue to prevent main thread blocking
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    // Completion handler for recording
    var recordingCompleted: ((URL?) -> Void)?
    
    // MARK: - Setup
    override init() {
        super.init()
        checkAuthorization()
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
