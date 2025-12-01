# Wedding Recorder

## Description

Wedding Recorder is an iOS application designed to simplify video and photo capture during special events (e.g., weddings). It features a configurable countdown timer for video recording, allows users to capture photo bursts, and provides a seamless way to share those captured memories via email.

## Features
*   **Dynamic Countdown Timer:** Configure video recording durations to 30 seconds, 1 minute, or 2 minutes.
*   **Photo Burst Mode:** Switch to photo mode for a 3-picture burst capture, complete with a 5-second countdown before each photo.
*   **Dynamic UI during Photo Capture:** Key UI elements (buttons, messages) intelligently hide during the photo burst sequence to maintain focus on the capture process.
*   **View Flip Animation:** A smooth visual flip effect indicates mode changes between video and photo, with UI elements remaining correctly oriented.
*   **Landscape Photo Saving:** Captured photos are automatically saved in the correct landscape orientation to the device's photo library.
*   **Settings Interface:** Easily access and modify countdown preferences.
*   **Camera Integration:** Seamless camera preview and video recording/photo capture functionality.
*   **Photo Library Integration:** Automatically saves recorded videos and captured photos to the device's photo library.
*   **Post-Recording "Thank You" Screen:** Provides a pleasant user experience after video recording is complete.
*   **Background Email Sharing:**
    *   Guests can enter their email after capturing photos to receive them directly.
    *   Emails are sent silently via a serverless API, ensuring a smooth user experience without launching the native Mail app.
    *   Captured photos are automatically optimized (resized and compressed) before sending to ensure successful delivery and avoid payload limits.
    *   The email modal dynamically updates to show sending progress, a success message, or a failure message.
    *   **Interactive Modal Timeout:** The email input modal features a 1-minute inactivity timeout. This timer resets with every user interaction (typing, button taps).
    *   **Smart Dismissal:**
        *   Upon successful email delivery (or after a 10-second auto-dismissal on the success screen), the camera automatically switches back to **Video Mode**.
        *   If the user manually cancels the email sending process, the camera intelligently returns to **Photo Burst Mode**.
    *   **Retry/Cancel on Failure:** If email sending fails, users are presented with clear options to "Reintentar" (Retry) or "Cancelar" (Cancel), along with a message confirming that photos remain saved locally.

## Installation

### Prerequisites
*   Xcode (version 15.0 or later recommended)
*   iOS device or simulator

### Steps
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/jorgedaaaah/WeddingRecorder.git
    ```
2.  **Open in Xcode:**
    Open the `.xcodeproj` file located in the cloned repository using Xcode.

3.  **Build and Run:**
    Select your target device (must be a physical iOS device) and run the project.

## Usage

1. **Start Recording:** Tap the central record button to begin the countdown and start video recording.
2. **Stop Recording:** Tap the stop button (visible during recording) to end the recording prematurely. If the countdown reaches zero, the video is automatically saved.
3. **Record New Video:** After a video is saved (either by manual stop or countdown completion), you can start a new recording.
4. **Access Settings:** While not recording, tap the gear icon in the top right corner to open the settings view and adjust the countdown duration.
5. **Switch to Photo Mode:** While not recording, tap the camera flip icon in the top left corner to switch to photo capture mode. The main button will change to a camera icon, and the flashing message will update.
6. **Capture Photo Burst:** In photo mode, tap the central camera button to initiate a 3-picture burst. A 5-second countdown will precede each photo, and the captured image will display for 2 seconds before proceeding to the next capture.
7.  **Send Photos via Email (New!):** After a photo burst, an email input modal will appear. Enter the recipient's email address and tap "Enviar" to send the photos.
    *   If successful, a confirmation message appears, and the modal will either auto-dismiss after 10 seconds or immediately upon tapping "Enviado!", returning you to **Video Mode**.
    *   If sending fails, you can "Reintentar" or "Cancelar", with photos remaining saved.
8. **Switch back to Video Mode:** Tap the camera flip icon again to return to video recording mode.

## Development Conventions
*   **Language:** The project is written entirely in Swift.
*   **UI Framework:** It uses SwiftUI for the user interface.
*   **State Management:** The application's state is managed using `@StateObject` and `ObservableObject`, with global state handled via `AppStateManager`.
*   **Architecture:** The code is organized into `Views`, `Models`, and `Services`.
    *   `Views`: Contains the SwiftUI views (`ContentView`, `CameraView`, `EmailInputDialogView`, etc.).
    *   `Models`: Defines the application's state (`RecordingState`, `Settings`, `AppStateManager` which now includes `CaptureMode`).
    *   `Services`: Encapsulates the logic for interacting with the camera (`CameraService`), saving videos (`VideoManager`), and handling network requests for email sending.
*   **Concurrency:** The application uses `async/await` for handling asynchronous tasks, particularly for the countdown timer and camera/network operations.
*   **Permissions:** The application correctly handles permissions for camera access and saving to the photo library.