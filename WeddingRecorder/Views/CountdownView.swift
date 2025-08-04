//
//  CountdownView.swift
//  WeddingRecorder
//
//  Created by Jorge on 8/2/25.
//

import SwiftUI

struct CountdownView: View {
    let number: Int
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // Countdown number - larger for landscape
            Text("\(number)")
                .font(.system(size: 150, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(scale)
                .opacity(opacity)
                .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 8)
        }
        .onAppear {
            animateCountdown()
        }
        .onChange(of: number) { _, _ in
            // Reset and animate when number changes
            scale = 0.5
            opacity = 0.0
            animateCountdown()
        }
    }
    
    private func animateCountdown() {
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 1.2
                opacity = 1.0
            }

            try? await Task.sleep(nanoseconds: 700_000_000) // 0.7s

            withAnimation(.easeIn(duration: 0.3)) {
                scale = 0.8
                opacity = 0.0
            }
        }
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        CountdownView(number: 3)
    }
}
