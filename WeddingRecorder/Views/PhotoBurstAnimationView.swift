import SwiftUI

// MARK: - PhotoBurstAnimationView
struct PhotoBurstAnimationView: View {
    let images: [UIImage]
    
    @State private var image1Scale: CGFloat = 1.0
    @State private var image2Scale: CGFloat = 1.0
    @State private var image3Scale: CGFloat = 1.0
    
    // Target zoom scale (115-125%)
    let targetScale: CGFloat = 2.0 // Zoom to 200%
    let animationDuration: TimeInterval = 0.5
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let totalHeight = geometry.size.height
            
            ZStack {
                // No explicit background color here, relying on blurred camera view behind
                
                if images.count == 3 {
                    // Layout for the three images in a loose collage
                    // Use a ZStack to allow for more flexible positioning and overlapping
                    ZStack {
                        let imageWidth = totalWidth * 0.4 // 40% of screen width
                        let imageHeight = totalHeight * 0.3 // 30% of screen height
                        
                        Image(uiImage: images[0])
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(image1Scale)
                            .frame(width: imageWidth, height: imageHeight)
                            .position(x: totalWidth * 0.25, y: totalHeight * 0.25) // Top-left quadrant
                        
                        Image(uiImage: images[1])
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(image2Scale)
                            .frame(width: imageWidth, height: imageHeight)
                            .position(x: totalWidth * 0.75, y: totalHeight * 0.25) // Top-right quadrant
                        
                        Image(uiImage: images[2])
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(image3Scale)
                            .frame(width: imageWidth, height: imageHeight)
                            .position(x: totalWidth * 0.5, y: totalHeight * 0.75) // Bottom-center
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onAppear {
                Task { @MainActor in // Use @MainActor to ensure UI updates happen on the main thread
                    // Phase 1: Zoom Image 1
                    try? await Task.sleep(for: .milliseconds(100)) // Small delay before first animation
                    withAnimation(.easeInOut(duration: animationDuration)) {
                        image1Scale = targetScale
                    }
                    try? await Task.sleep(for: .seconds(animationDuration))
                    
                    // Phase 2: Zoom Image 2
                    withAnimation(.easeInOut(duration: animationDuration)) {
                        image2Scale = targetScale
                    }
                    try? await Task.sleep(for: .seconds(animationDuration))
                    
                    // Phase 3: Zoom Image 3
                    withAnimation(.easeInOut(duration: animationDuration)) {
                        image3Scale = targetScale
                    }
                    // No need for final sleep here, as CameraService will handle the total display duration.
                }
            }
        }
    }
}
