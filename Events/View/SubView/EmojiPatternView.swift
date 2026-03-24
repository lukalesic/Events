import SwiftUI
/// A view that renders a scattered emoji pattern over a color background.
/// Used as a placeholder header when an event has no custom image.
struct EmojiPatternView: View {
    let emoji: String
    let color: Color
    
    // Precomputed random positions/sizes/rotations for consistency
    private let items: [EmojiItem]
    
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
                
                // Scattered emojis
                ForEach(items.indices, id: \.self) { i in
                    let item = items[i]
                    let displayEmoji = emoji.isEmpty ? "📅" : emoji
                    Text(displayEmoji)
                        .font(.system(size: item.size))
                        .rotationEffect(.degrees(item.rotation))
                        .opacity(item.opacity)
                        .position(
                            x: item.x * geo.size.width,
                            y: item.y * geo.size.height
                        )
                }
            }
        }
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
