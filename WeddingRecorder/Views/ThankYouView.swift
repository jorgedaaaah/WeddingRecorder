//
//  ThankYouView.swift
//  WeddingRecorder
//
//  Created by Jorge on 8/2/25.
//

import SwiftUI

struct ThankYouView: View {
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var checkmarkScale: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.8),
                    Color.blue.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Checkmark icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkmarkScale)
                }
                
                // Thank you message
                VStack(spacing: 16) {
                    Text("Thank You!")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(scale)
                    
                    Text("Your video has been saved to Photos")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(opacity)
                }
            }
        }
        .onAppear {
            animateEntry()
        }
    }
    
    private func animateEntry() {
        // Animate background elements first
        withAnimation(.easeOut(duration: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Delay checkmark animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                checkmarkScale = 1.0
            }
        }
        
        // Auto-dismiss after 5 seconds (handled in ContentView)
    }
}

#Preview {
    ThankYouView(onDismiss: { print("Dismissed") })
}
