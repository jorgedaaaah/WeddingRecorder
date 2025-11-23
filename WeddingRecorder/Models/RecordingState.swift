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
