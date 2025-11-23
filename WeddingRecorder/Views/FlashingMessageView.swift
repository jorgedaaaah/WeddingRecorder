//
//  FlashingMessageView.swift
//  WeddingRecorder
//
//  Created by Jorge on 11/23/25.
//

import SwiftUI
import Combine

/// A SwiftUI view that displays a flashing message.
/// The message appears and disappears with specified durations,
/// providing a visual cue to the user.
struct FlashingMessageView: View {
    @State private var isVisible: Bool = true
    @State private var cancellable: AnyCancellable?
    
    let message: String
    let displayDuration: TimeInterval
    let hideDuration: TimeInterval
    
    /// Initializes the flashing message view.
    /// - Parameters:
    ///   - message: The text message to display. Defaults to "PRESIONA EL BOTON ROJO PARA COMENZAR A GRABAR".
    ///   - displayDuration: The duration for which the message is visible. Defaults to 2 seconds.
    ///   - hideDuration: The duration for which the message is hidden. Defaults to 1 second.
    init(message: String = "PRESIONA EL BOTON ROJO PARA COMENZAR A GRABAR", displayDuration: TimeInterval = 2, hideDuration: TimeInterval = 1) {
        self.message = message
        self.displayDuration = displayDuration
        self.hideDuration = hideDuration
    }
    
    var body: some View {
        Text(message)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .textCase(.uppercase)
            .padding(.bottom, 20)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.5), value: isVisible) // Smooth fade
            .onAppear(perform: startFlashing)
            .onDisappear(perform: stopFlashing)
    }
    
    private func startFlashing() {
        isVisible = true // Start visible

        cancellable = Timer.publish(every: displayDuration + hideDuration, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                // On each cycle start, make it visible
                isVisible = true
                // Then schedule to hide it after displayDuration
                DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
                    isVisible = false
                }
            }
        
        // Initial hide after displayDuration for the very first appearance
        // This ensures the first cycle is consistent with subsequent cycles.
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
            isVisible = false
        }
    }
    
    private func stopFlashing() {
        cancellable?.cancel()
        cancellable = nil // Clear the cancellable
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        FlashingMessageView(message: "PRESIONA EL BOTON ROJO PARA COMENZAR A GRABAR", displayDuration: 2, hideDuration: 1)
    }
}