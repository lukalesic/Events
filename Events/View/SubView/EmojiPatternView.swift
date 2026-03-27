import SwiftUI
import CoreMotion

/// A view that renders a scattered emoji pattern over a color background.
/// Used as a placeholder header when an event has no custom image.
/// Combines device-tilt parallax with a gentle breathing animation.
struct EmojiPatternView: View {
    let emoji: String
    let color: Color
    
    // Precomputed random positions/sizes/rotations for consistency
    private let items: [EmojiItem]
    
    @StateObject private var motion = MotionManager()
    @State private var animate = false
    
    init(emoji: String, color: Color, count: Int = 30, seed: Int = 42) {
        self.emoji = emoji
        self.color = color
        
        // Use a seeded random generator for deterministic layout
        var rng = SeededRandomNumberGenerator(seed: UInt64(bitPattern: Int64(seed)))
        var generated: [EmojiItem] = []
        for _ in 0..<count {
            generated.append(
                EmojiItem(
                    x: Double.random(in: 0...1, using: &rng),
                    y: Double.random(in: 0...1, using: &rng),
                    size: Double.random(in: 22...48, using: &rng),
                    rotation: Double.random(in: -30...30, using: &rng),
                    opacity: Double.random(in: 0.15...0.70, using: &rng)
                )
            )
        }
        self.items = generated
    }
    
    // How many points the emoji layer shifts per degree of tilt
    private let parallaxStrength: CGFloat = 18
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Rich gradient background using the event color
                LinearGradient(
                    colors: [
                        color.opacity(0.55),
                        color.opacity(0.40),
                        color.opacity(0.35)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Scattered emojis — single Canvas for performance
                Canvas { context, size in
                    let displayEmoji = emoji.isEmpty ? "📅" : emoji
                    for item in items {
                        let resolved = context.resolve(
                            Text(displayEmoji)
                                .font(.system(size: item.size))
                        )
                        let textSize = resolved.measure(in: size)
                        let x = item.x * size.width
                        let y = item.y * size.height
                        
                        var transform = CGAffineTransform.identity
                        transform = transform.translatedBy(x: x, y: y)
                        transform = transform.rotated(by: item.rotation * .pi / 180)
                        transform = transform.translatedBy(x: -textSize.width / 2, y: -textSize.height / 2)
                        
                        context.opacity = item.opacity
                        context.drawLayer { layerCtx in
                            layerCtx.concatenate(transform)
                            layerCtx.draw(resolved, at: .zero, anchor: .topLeading)
                        }
                    }
                }
                // Layer 1: Parallax — device tilt drives offset
                .offset(
                    x: motion.xTilt * parallaxStrength,
                    y: motion.yTilt * parallaxStrength
                )
                // Layer 2: Breathing — gentle drift + scale loop
                .offset(
                    x: animate ? 15 : -13,
                    y: animate ? -9 : 9
                )
                .scaleEffect(animate ? 1.03 : 0.95)
                // Spring for parallax so tilt feels responsive
                .animation(.interpolatingSpring(stiffness: 60, damping: 15), value: motion.xTilt)
                .animation(.interpolatingSpring(stiffness: 60, damping: 15), value: motion.yTilt)
                // Slow ease for breathing so it feels organic
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)
            }
        }
        .clipped()
        .drawingGroup() // Flatten to single GPU layer for performance
        .onAppear { animate = true }
    }
}

// MARK: - Motion Manager

/// Lightweight wrapper around CMMotionManager that publishes device tilt.
/// Reads at 30 Hz — very low overhead. Falls back to zero on simulator.
private final class MotionManager: ObservableObject {
    @Published var xTilt: CGFloat = 0
    @Published var yTilt: CGFloat = 0
    
    private let manager = CMMotionManager()
    
    init() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30 // 30 Hz is plenty
        manager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let data = data, let self = self else { return }
            // attitude.roll = side tilt, attitude.pitch = forward/back tilt
            // Clamp to ±1 range for a subtle effect
            self.xTilt = max(-1, min(1, data.attitude.roll))
            self.yTilt = max(-1, min(1, data.attitude.pitch))
        }
    }
    
    deinit {
        manager.stopDeviceMotionUpdates()
    }
}

// MARK: - Supporting Types

private struct EmojiItem {
    let x: Double
    let y: Double
    let size: Double
    let rotation: Double
    let opacity: Double
}

/// A simple seeded random number generator for deterministic layouts.
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
