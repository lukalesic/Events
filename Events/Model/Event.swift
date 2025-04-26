//
//  Event.swift
//  Events
//
//  Created by Luka Lešić on 20.04.25.
//

import Foundation
import SwiftUI
import UIKit
import SwiftData

@Model
class Event {
    var id: UUID
    var colorHex: String
    var daysLeft: Int
    var name: String
    var descriptionText: String
    var emoji: String
    var priority: EventPriority
    var date: Date
    var photoData: Data?
    var repeatFrequency: RepeatFrequency
    
    // Computed property for color
    var color: Color {
        get { Color(hex: colorHex) ?? Event.randomColor() }
        set { colorHex = newValue.toHex() ?? "#808080" }
    }
    
    var isPast: Bool {
        daysLeftUntilNextDate < 0
    }
    
    var isToday: Bool {
        daysLeftUntilNextDate == 0
    }
    
    var isUpcoming: Bool {
        daysLeftUntilNextDate > 0
    }
    
    // Computed property for photo
    var photo: UIImage? {
        get {
            if let photoData = photoData {
                return UIImage(data: photoData)
            }
            return nil
        }
        set {
            if let newValue = newValue, let data = newValue.jpegData(compressionQuality: 0.8) {
                photoData = data
            } else {
                photoData = nil
            }
        }
    }
    
    var previewImage: UIImage? {
        guard let data = photoData,
              let image = UIImage(data: data) else { return nil }
        
        let targetSize = CGSize(width: 50, height: 40)
        return image.resized(to: targetSize)
    }
    
    init(id: UUID = UUID(),
         color: Color = Event.randomColor(),
         daysLeft: Int = 0,
         name: String = "",
         descriptionText: String = "",
         emoji: String = "",
         priority: EventPriority = .medium,
         date: Date = Date.now,
         photo: UIImage? = nil,
         repeatFrequency: RepeatFrequency = .none) {
        self.id = id
        self.colorHex = color.toHex() ?? "#808080"
        self.daysLeft = daysLeft
        self.name = name
        self.descriptionText = descriptionText
        self.emoji = emoji
        self.priority = priority
        self.date = date
        self.repeatFrequency = repeatFrequency
        
        if let photo = photo, let data = photo.jpegData(compressionQuality: 0.8) {
            self.photoData = data
        } else {
            self.photoData = nil
        }
    }
    
    static func randomColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        return colors.randomElement() ?? .gray
    }
}

// Extensions for calculated properties
extension Event {
    var nextDate: Date {
        switch repeatFrequency {
        case .daily:
            return Calendar.current.nextDate(after: .now, matching: Calendar.current.dateComponents([.hour, .minute, .second], from: date), matchingPolicy: .nextTimePreservingSmallerComponents) ?? date
        case .weekly:
            return Calendar.current.nextDate(after: .now, matching: Calendar.current.dateComponents([.weekday, .hour, .minute, .second], from: date), matchingPolicy: .nextTimePreservingSmallerComponents) ?? date
        case .monthly:
            let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: date)
            return Calendar.current.nextDate(after: .now, matching: components, matchingPolicy: .nextTimePreservingSmallerComponents) ?? date
        case .yearly:
            let components = Calendar.current.dateComponents([.month, .day, .hour, .minute, .second], from: date)
            return Calendar.current.nextDate(after: .now, matching: components, matchingPolicy: .nextTimePreservingSmallerComponents) ?? date
        case .none:
            return date
        }
    }

    var daysLeftUntilNextDate: Int {
        let today = Calendar.current.startOfDay(for: .now)
        let target = Calendar.current.startOfDay(for: nextDate)
        return Calendar.current.dateComponents([.day], from: today, to: target).day ?? 0
    }
}

// Helper extensions for Color handling
extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255))
    }
    
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}


extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

extension Event {
    var blurredPreviewImage: UIImage? {
        guard let photo = previewImage else { return nil }
        return photo.applyBlur(radius: 1.5)
    }
}

import CoreImage
import CoreImage.CIFilterBuiltins

extension UIImage {
    func applyBlur(radius: CGFloat) -> UIImage? {
        let context = CIContext()
        let inputImage = CIImage(image: self)
        
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = inputImage
        filter.radius = Float(radius)
        
        guard let outputImage = filter.outputImage,
              let cgimg = context.createCGImage(outputImage, from: inputImage!.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgimg)
    }
}
