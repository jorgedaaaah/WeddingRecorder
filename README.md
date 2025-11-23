# Wedding Recorder

## Description

Wedding Recorder is an iOS application designed to simplify video recording during special events (e.g. poditos wedding). It features a configurable countdown timer, allowing users to set recording durations to 30 seconds, 1 minute, or 2 minutes, ensuring precise capture of memorable moments.

## Features
*   **Dynamic Countdown Timer:** Configure recording durations to 30 seconds, 1 minute, or 2 minutes.
*   **Photo Burst Mode:** Switch to photo mode for a 3-picture burst capture, complete with a 5-second countdown before each photo.
*   **Dynamic UI during Photo Capture:** Key UI elements (buttons, messages) intelligently hide during the photo burst sequence to maintain focus on the capture process.
*   **View Flip Animation:** A smooth visual flip effect indicates mode changes between video and photo, with UI elements remaining correctly oriented.
*   **Landscape Photo Saving:** Captured photos are automatically saved in the correct landscape orientation to the device's photo library.
*   **Settings Interface:** Easily access and modify countdown preferences.
*   **Camera Integration:** Seamless camera preview and video recording functionality.
*   **Photo Library Integration:** Automatically saves recorded videos to the device's photo library.
*   **Post-Recording "Thank You" Screen:** Provides a pleasant user experience after recording is complete.

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
7. **Switch back to Video Mode:** Tap the camera flip icon again to return to video recording mode.
