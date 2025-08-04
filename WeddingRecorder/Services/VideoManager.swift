//
//  VideoManager.swift
//  WeddingRecorder
//
//  Created by Jorge on 8/2/25.
//

import Photos
import UIKit

@MainActor
class VideoManager: ObservableObject {
    
    @Published var isAuthorized = false
    
    init() {
        checkPhotoLibraryAuthorization()
    }
    
    // MARK: - Authorization
    func checkPhotoLibraryAuthorization() {
        #if targetEnvironment(simulator)
        // In simulator, just set authorized to true for testing
        isAuthorized = true
        print("Simulator detected - photo library simulation enabled")
        #else
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            isAuthorized = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
                DispatchQueue.main.async {
                    self?.isAuthorized = (status == .authorized || status == .limited)
                }
            }
        case .denied, .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
        #endif
    }
    
    // MARK: - Save Video
    func saveVideoToPhotoLibrary(url: URL, completion: @escaping (Bool, Error?) -> Void) {
        #if targetEnvironment(simulator)
        // Simulate saving in simulator
        print("Simulating video save to photo library...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(true, nil)
        }
        return
        #else
        guard isAuthorized else {
            completion(false, VideoManagerError.notAuthorized)
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
                
                // Clean up temporary file
                self.deleteTemporaryFile(at: url)
            }
        }
        #endif
    }
    
    // MARK: - Cleanup
    private func deleteTemporaryFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            print("Temporary video file deleted successfully")
        } catch {
            print("Error deleting temporary file: \(error.localizedDescription)")
        }
    }
}

// MARK: - Errors
enum VideoManagerError: LocalizedError {
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Photos library access not authorized"
        }
    }
}
