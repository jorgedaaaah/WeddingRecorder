//
//  CameraView.swift
//  WeddingRecorder
//
//  Created by Jorge on 8/2/25.
//

import SwiftUI
import AVFoundation

enum CaptureMode {
    case video
    case photo
}

struct CameraView: View {
    @Binding var captureMode: CaptureMode // Now a Binding
    
    var isPhotoMode: Bool { captureMode == .photo }
    
    // MARK: - Properties
    @ObservedObject var cameraService: CameraService
    let onRecordTapped: () -> Void
    var remainingRecordingTime: Int = 0
    var totalRecordingDuration: Int = 0
    var onStopRecording: (() -> Void)? = nil
    var onSettingsTapped: (() -> Void)? = nil
    var onCapturePhotoTapped: (() -> Void)? = nil
    
    var isRecording: Bool {
        remainingRecordingTime > 0 && remainingRecordingTime <= totalRecordingDuration
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview layer - ALWAYS VISIBLE
                if cameraService.isAuthorized {
                    CameraPreviewLayer(session: cameraService.session)
                        .ignoresSafeArea()
                        .rotation3DEffect(.degrees(isPhotoMode ? -180 : 0), axis: (x: 0, y: 1, z: 0)) // Counter-rotation for camera preview
                        .blur(radius: {
                            switch cameraService.photoCaptureState {
                            case .showingBurstAnimation, .showingEmailInput:
                                return 10
                            default:
                                return 0
                            }
                        }()) // Apply blur when showing burst animation OR email input
                } else {
                    // Placeholder when camera not available
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 20) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                
                                Text(getPlaceholderText())
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                        )
                }
                
                // UI Overlay
                VStack {
                    if !isRecording && cameraService.photoCaptureState == .idle {
                        HStack {
                            Button(action: {
                                withAnimation {
                                    captureMode = captureMode == .video ? .photo : .video
                                }
                            }) {
                                Group {
                                    if isPhotoMode {
                                        Image(systemName: "video.fill") // Icon for switching to video mode
                                            .font(.system(size: 30))
                                            .foregroundColor(.red) // Red color for indicating video recording
                                    } else {
                                        Image(systemName: "camera.rotate.fill") // Original icon for mode switch
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                            }
                            Spacer()
                            Button(action: {
                                onSettingsTapped?()
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Recording controls
                    HStack {
                        Spacer()
                        
                        if isRecording {
                            // Recording indicator and stop button
                            VStack {
                                Spacer()
                                
                                HStack {
                                    // Recording indicator (top-left when in landscape)
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 12, height: 12)
                                                .scaleEffect(1.0)
                                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isRecording)
                                            
                                            Text("REC")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.red)
                                        }
                                        .padding(.leading, 40)
                                        .padding(.top, 40)
                                        
                                        // Recording countdown (below REC)
                                        Text("\(remainingRecordingTime)s")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(remainingRecordingTime <= 5 ? .red : .white)
                                            .padding(.leading, 40)
                                    }
                                    
                                    Spacer()
                                    // Stop recording button (bottom-right)
                                    Button(action: {
                                        onStopRecording?()
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 70, height: 70)
                                            
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white)
                                                .frame(width: 25, height: 25)
                                        }
                                    }
                                    .padding(.trailing, 40)
                                    .padding(.bottom, 40)
                                }
                            }
                        } else if cameraService.photoCaptureState == .idle {
                            // Record button (centered)
                            Group {
                                if isPhotoMode {
                                    Button(action: { onCapturePhotoTapped?() }) {
                                        ZStack {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 8)
                                                .frame(width: 100, height: 100)
                                            
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white)
                                        }
                                    }
                                } else {
                                    Button(action: onRecordTapped) {
                                        ZStack {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 8)
                                                .frame(width: 100, height: 100)
                                            
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 75, height: 75)
                                        }
                                    }
                                }
                            }
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.1), value: isRecording)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 60)
                    
                    if !isRecording && cameraService.photoCaptureState == .idle {
                        FlashingMessageView(message: isPhotoMode ? "Presiona el boton para tomar tres fotos en rafaga" : "PRESIONA EL BOTON ROJO PARA COMENZAR A GRABAR", displayDuration: 2, hideDuration: 1)
                    }
                }
                .rotation3DEffect(.degrees(isPhotoMode ? -180 : 0), axis: (x: 0, y: 1, z: 0)) // Counter-rotation for UI
                .opacity({
                    switch cameraService.photoCaptureState {
                    case .showingBurstAnimation, .showingEmailInput:
                        return 0
                    default:
                        return 1
                    }
                }()) // Hide UI during burst animation OR email input
                
                // MARK: - Overlays for Photo Burst
                switch cameraService.photoCaptureState {
                case .countdown(let count):
                    Text("\(count)")
                        .font(.system(size: 100, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.animation(.easeInOut))
                        .id("countdown_text") // Add an ID to ensure unique view identity for transitions
                        .rotation3DEffect(.degrees(isPhotoMode ? -180 : 0), axis: (x: 0, y: 1, z: 0)) // Counter-rotation for countdown
                case .displayingPhoto(let image):
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                        .id("displayed_photo") // Add an ID
                case .idle:
                    EmptyView()
                case .showingBurstAnimation(let images):
                    PhotoBurstAnimationView(images: images)
                        .transition(.opacity.animation(.easeInOut(duration: 0.5))) // Flash transition
                case .showingEmailInput:
                    EmailInputDialogView(email: $cameraService.emailInput, dismissAction: cameraService.dismissEmailInput, cameraService: cameraService, onUserInteraction: cameraService.resetEmailInputTimeout)
                        .transition(.move(edge: .bottom).animation(.easeOut(duration: 1.0))) // Bottom to center transition
                        .rotation3DEffect(.degrees(isPhotoMode ? -180 : 0), axis: (x: 0, y: 1, z: 0)) // Counter-rotation for email dialog
                }
            }
            .rotation3DEffect(.degrees(isPhotoMode ? 180 : 0), axis: (x: 0, y: 1, z: 0)) // Main rotation for ZStack
            .animation(.default, value: isPhotoMode)
        }
    }
    // Helper function to determine placeholder text
    private func getPlaceholderText() -> String {
        #if targetEnvironment(simulator)
        return "Camera simulation not available\nConnect a physical device for full testing"
        #else
        return cameraService.isAuthorized ? "Starting camera..." : "Camera access required"
        #endif
    }
}

// MARK: - Camera Preview Layer - FIXED UI THREADING
struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Minimal updates only
        if uiView.session != session {
            uiView.session = session
        }
        
        // Ensure the preview layer's connection orientation matches the app's landscapeRight
        if let connection = uiView.videoPreviewLayer.connection, connection.isVideoRotationAngleSupported(90) {
            if connection.videoRotationAngle != 90 { // Only update if necessary to prevent unnecessary redraws
                connection.videoRotationAngle = 90
            }
        }
    }
}

// MARK: - FIXED Custom Preview View - NO MORE UI THREAD ISSUES
class PreviewView: UIView {
    private static var hasConfiguredGlobally = false
    
    var session: AVCaptureSession? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.videoPreviewLayer.session = self.session
                
                if self.session != nil && !PreviewView.hasConfiguredGlobally {
                    self.configureOrientationOnce()
                }
            }
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPreviewLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPreviewLayer()
    }
    
    private func setupPreviewLayer() {
        // Configure on main thread only
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.videoPreviewLayer.videoGravity = .resizeAspectFill
            
            // Set initial rotation for landscapeRight
            if let connection = self.videoPreviewLayer.connection, connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
                print("✅ PreviewLayer rotation angle set to 90 degrees during setup.")
            }
        }
    }
    
    private func configureOrientationOnce() {
        guard !PreviewView.hasConfiguredGlobally else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            guard let connection = self.videoPreviewLayer.connection else {
                print("❌ No preview connection found")
                return
            }
            
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .landscapeRight
                print("✅ Preview orientation set to landscapeRight")
            }
            

            
            PreviewView.hasConfiguredGlobally = true
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.videoPreviewLayer.frame = self.bounds
    }
}

#Preview {
    CameraView(
        captureMode: .constant(.video), // Provide a constant binding for preview
        cameraService: CameraService(),
        onRecordTapped: { print("Record tapped") },
        remainingRecordingTime: 30,
        totalRecordingDuration: 30
    )
}
