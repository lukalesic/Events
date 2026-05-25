import UIKit

extension UIImage {
    /// Returns `true` if the image's average color is considered light.
    var isLight: Bool? {
        guard let cgImage = self.cgImage else { return nil }
        
        // Downsample to 40x40 for performance
        let size = CGSize(width: 40, height: 40)
        let width = Int(size.width)
        let height = Int(size.height)
        let totalPixels = width * height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: totalPixels * 4)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        var totalBrightness: Double = 0
        
        for i in 0..<totalPixels {
            let offset = i * 4
            let r = Double(pixelData[offset]) / 255.0
            let g = Double(pixelData[offset + 1]) / 255.0
            let b = Double(pixelData[offset + 2]) / 255.0
            // Perceived brightness formula
            totalBrightness += (0.299 * r + 0.587 * g + 0.114 * b)
        }
        
        let averageBrightness = totalBrightness / Double(totalPixels)
        return averageBrightness > 0.7
    }
}
