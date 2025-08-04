//
//  RecordingState.swift
//  WeddingRecorder
//
//  Created by Jorge on 8/2/25.
//

import Foundation

// MARK: - Recording States
enum RecordingState: Equatable {
    case idle           // Showing camera preview, ready to record
    case countdown(Int) // Showing countdown (3, 2, 1)
    case recording      // Currently recording video
    case thankYou       // Showing thank you message
}

// MARK: - App State Manager
@MainActor
class AppStateManager: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""
    
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
    
    func startRecording() {
        recordingState = .recording
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
