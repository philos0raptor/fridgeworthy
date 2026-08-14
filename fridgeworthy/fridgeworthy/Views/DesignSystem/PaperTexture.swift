import SwiftUI

/// Procedural paper-grain noise overlay. Used on SignIn, ChildDetail hero, and Paywall backgrounds.
struct PaperTexture: View {
    var opacity: Double = 0.4

    var body: some View {
        Canvas { context, size in
            // Draw a grid of tiny semi-random dots to simulate paper grain
            let step: CGFloat = 3
            var x: CGFloat = 0
            var seed: UInt64 = 42
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    // Simple hash for deterministic pseudo-random noise
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    let value = Double((seed >> 33) & 0xFF) / 255.0
                    if value > 0.45 {
                        let dotOpacity = (value - 0.45) * 1.8
                        let rect = CGRect(x: x, y: y, width: 1.5, height: 1.5)
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(.black.opacity(dotOpacity * 0.15))
                        )
                    }
                    y += step
                }
                x += step
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
    }
}
