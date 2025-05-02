//
//  WidgetEvent.swift
//  Events
//
//  Created by Luka Lešić on 02.05.25.
//


// WidgetSampleEvent.swift

import Foundation
import SwiftUI

struct WidgetEvent: Codable, Identifiable {
    var id: UUID
    var colorHex: String
    var name: String
    var emoji: String
    var date: Date
    
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
    
    var daysLeftUntilNextDate: Int {
        let today = Calendar.current.startOfDay(for: .now)
        let target = Calendar.current.startOfDay(for: date)
        return Calendar.current.dateComponents([.day], from: today, to: target).day ?? 0
    }
}

extension WidgetEvent {
    static let sample = WidgetEvent(
        id: UUID(),
        colorHex: "#FF5733",
        name: "Sample Event",
        emoji: "🎉",
        date: Calendar.current.date(byAdding: .day, value: 5, to: .now)!
    )
}

// Helper to convert hex string to Color
extension Color {
    init?(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        guard let int = Int(hex, radix: 16) else { return nil }
        let red = Double((int >> 16) & 0xFF) / 255
        let green = Double((int >> 8) & 0xFF) / 255
        let blue = Double(int & 0xFF) / 255
        self = Color(red: red, green: green, blue: blue)
    }
}