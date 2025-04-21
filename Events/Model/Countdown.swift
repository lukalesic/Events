//
//  Countdown.swift
//  Events
//
//  Created by Luka Lešić on 20.04.25.
//

import Foundation
import SwiftUICore
import UIKit
import SwiftData

struct Countdown: Identifiable {
    var id = UUID()
    var color: Color = Countdown.randomColor()
    var daysLeft: Int
    var name: String
    var description: String
    var emoji: String
    var priority: Priority
    var date: Date
    var photo: UIImage? = nil
    var repeatFrequency: RepeatFrequency = .none

    static func randomColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        return colors.randomElement() ?? .gray
    }
}

extension Countdown {
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





