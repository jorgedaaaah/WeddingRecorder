//
//  AppStateManager.swift
//  WeddingRecorder
//
//  Created by Jorge on 8/2/25.
//

import Foundation

// MARK: - App State Manager
@MainActor
class AppStateManager: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""
    @Published var remainingRecordingTime: Int = 0
    
    // MARK: - State Transitions
    func startCountdown() {
        recordingState = .countdown(3)
    }
    
    func updateCountdown(to number: Int) {
        if number > 0 {
            recordingState = .countdown(number)
        } else {
            recordingState = .recording
        }
    }
    
    func startRecording(duration: Int) {
        recordingState = .recording
        remainingRecordingTime = duration
    }
    
    func stopRecording() {
        recordingState = .thankYou
    }
    
    func resetToIdle() {
        recordingState = .idle
    }
    
    func showError(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
    
    func clearError() {
        isShowingError = false
        errorMessage = ""
    }
}

enum CaptureMode {
    case video
    case photo
}
