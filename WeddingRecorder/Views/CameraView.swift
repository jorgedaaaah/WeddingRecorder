//
//  CameraView.swift
//  WeddingRecorder
//
//  Created by Jorge on 8/2/25.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    
    // MARK: - Properties
    let cameraService: CameraService
    let onRecordTapped: () -> Void
    var remainingRecordingTime: Int = 0
    var totalRecordingDuration: Int = 0
    var onStopRecording: (() -> Void)? = nil
    var onSettingsTapped: (() -> Void)? = nil
    
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
                    if !isRecording {
                        HStack {
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
                        } else {
                            // Record button (centered)
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
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.1), value: isRecording)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 60)
                }
            }
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
            self?.videoPreviewLayer.videoGravity = .resizeAspectFill
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

            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
                print("✅ Preview mirroring enabled")
            }

            PreviewView.hasConfiguredGlobally = true
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async { [weak self] in
            self?.videoPreviewLayer.frame = self?.bounds ?? .zero
        }
    }
}

#Preview {
    CameraView(
        cameraService: CameraService(),
        onRecordTapped: { print("Record tapped") },
        remainingRecordingTime: 30,
        totalRecordingDuration: 30
    )
}
