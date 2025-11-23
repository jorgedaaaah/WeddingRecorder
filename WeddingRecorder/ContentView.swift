//
//  ContentView.swift
//  WeddingRecorder
//
//  Created by Jorge on 8/2/25.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - State Management
    @EnvironmentObject private var settings: Settings
    @StateObject private var appState = AppStateManager()
    @StateObject private var cameraService = CameraService()
    @StateObject private var videoManager = VideoManager()
    @StateObject private var countdown = Countdown()
    
    @State private var isSettingsPresented = false
    
    var body: some View {
        ZStack {
            // Always keep the live camera preview mounted
            CameraView(
                cameraService: cameraService,
                onRecordTapped: startRecordingFlow,
                remainingRecordingTime: appState.remainingRecordingTime,
                totalRecordingDuration: settings.countdownDuration.rawValue,
                onStopRecording: appState.recordingState == .recording ? stopRecording : nil,
                onSettingsTapped: { isSettingsPresented.toggle() }
            )

            // UI overlays by state
            switch appState.recordingState {
            case .countdown(let number):
                CountdownView(number: number)

            case .thankYou:
                ThankYouView(onDismiss: returnToCamera)

            default:
                EmptyView()
            }
        }
        .onAppear {
            setupCamera()
            forceLandscapeOrientation()
        }
        .alert("Error", isPresented: $appState.isShowingError) {
            Button("OK") {
                appState.clearError()
            }
        } message: {
            Text(appState.errorMessage)
        }
        .persistentSystemOverlays(.hidden) // Hide system UI for immersive experience
        .statusBarHidden() // Hide status bar
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView()
                .environmentObject(settings)
        }
        .onChange(of: appState.remainingRecordingTime) { newValue in
            if newValue > 0 {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1))
                    if appState.recordingState == .recording {
                        appState.remainingRecordingTime -= 1
                    }
                }
            }
        }
    }
    
    // MARK: - Orientation Control
    private func forceLandscapeOrientation() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(
            interfaceOrientations: .landscapeRight
        )
        
        windowScene.requestGeometryUpdate(geometryPreferences) { error in
            print("Geometry update error: \(error)")
        }
    }
    
    // MARK: - Actions
    private func setupCamera() {
        print("📱 Setting up camera in ContentView...")
        
        // Set up recording completion handler
        cameraService.recordingCompleted = { [weak appState, weak videoManager] videoURL in
            guard let appState = appState else { return }
            
            #if targetEnvironment(simulator)
            // In simulator, just show thank you without saving
            appState.stopRecording()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                appState.resetToIdle()
            }
            #else
            guard let videoManager = videoManager,
                  let url = videoURL else {
                appState.showError("Recording failed")
                appState.resetToIdle()
                return
            }
            
            // Save video to Photos library
            videoManager.saveVideoToPhotoLibrary(url: url) { success, error in
                if success {
                    appState.stopRecording()
                    // ThankYou view will auto-dismiss after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        appState.resetToIdle()
                    }
                } else {
                    appState.showError(error?.localizedDescription ?? "Failed to save video")
                    appState.resetToIdle()
                }
            }
            #endif
        }
        
        // Start the camera session once configured
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.cameraService.isSessionConfigured && !self.cameraService.isSessionRunning {
                print("📱 Starting camera session from ContentView...")
                self.cameraService.startSession()
                
                // 🔁 Wait before enabling recording
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("📱 Camera session should now be fully ready")
                }
            }
        }
    }
    
    private func startRecordingFlow() {
        guard cameraService.isAuthorized else {
            appState.showError("Camera access is required to record videos")
            return
        }
        
        guard cameraService.isSessionRunning else {
            appState.showError("Camera is not ready. Please wait and try again.")
            return
        }
        
        appState.startCountdown()
        countdown.start(
            from: 3,
            onUpdate: { number in
                appState.updateCountdown(to: number)
            },
            onFinish: {
                appState.startRecording(duration: settings.countdownDuration.rawValue)
                cameraService.startRecording()
                
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(settings.countdownDuration.rawValue) * 1_000_000_000)
                    if case .recording = appState.recordingState {
                        stopRecording()
                    }
                }
            }
        )
    }
    
    private func stopRecording() {
        cameraService.stopRecording()
        appState.remainingRecordingTime = 0
        // Note: appState.stopRecording() will be called in the completion handler
    }
    
    private func returnToCamera() {
        appState.resetToIdle()
    }
}

// MARK: - Permission View
struct PermissionView: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                Text("Camera Access Required")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Wedding Recorder needs camera access to record videos. Please enable camera permissions in Settings.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Retry") {
                    onRetry()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.black)
            .font(.headline)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.headline)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.2))
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
