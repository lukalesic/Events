//
//  CountdownViewModel.swift
//  Events
//
//  Created by Luka Lešić on 23.03.25.
//

import Foundation
import SwiftUI
import Observation

@Observable
class CountdownViewModel {
    
    var countdowns: [Countdown] = []
    var selectedDisplayMode: TimeDisplayMode = .days
    
    init() {
        
        //TODO delete
        let testCountdown2 = Countdown(daysLeft: 33, name: "name", description: "desc", emoji: "🔥", priority: .small, date: .now)
                
        self.countdowns.append(testCountdown2)
    }
}

extension CountdownViewModel {
    
    func addCountdown(_ countdown: Countdown) {
        countdowns.append(countdown)
    }
    
    func updateCountdown(_ updated: Countdown) {
        if let index = countdowns.firstIndex(where: { $0.id == updated.id }) {
            countdowns[index] = updated
        }
    }
    
    func deleteCountdown(_ countdown: Countdown) {
        if let index = countdowns.firstIndex(where: { $0.id == countdown.id }) {
            countdowns.remove(at: index)
        }
    }
    
    func updatePriority(for id: UUID, to newPriority: Priority) {
        if let index = countdowns.firstIndex(where: { $0.id == id }) {
            countdowns[index].priority = newPriority
        }
    }
    
    func updatePhoto(for id: UUID, image: UIImage) {
        if let index = countdowns.firstIndex(where: { $0.id == id }) {
            countdowns[index].photo = image
        }
    }
    
    func adjustedDate(for countdown: Countdown) -> Date {
        var nextDate = countdown.date
        let now = Date()

        while nextDate < now {
            switch countdown.repeatFrequency {
            case .daily:
                nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            case .weekly:
                nextDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: nextDate) ?? nextDate
            case .monthly:
                nextDate = Calendar.current.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
            case .yearly:
                nextDate = Calendar.current.date(byAdding: .year, value: 1, to: nextDate) ?? nextDate
            case .none:
                break
            }
            if countdown.repeatFrequency == .none { break }
        }

        return nextDate
    }
    
    func formattedTimeRemaining(for countdown: Countdown) -> String {
        let now = Calendar.current.startOfDay(for: .now)
        let target = Calendar.current.startOfDay(for: adjustedDate(for: countdown))
        let totalDays = Calendar.current.dateComponents([.day], from: now, to: target).day ?? 0

        switch selectedDisplayMode {
        case .days:
            return "\(totalDays) day\(totalDays == 1 ? "" : "s")"
            
        case .weeks:
            let weeks = totalDays / 7
            let days = totalDays % 7
            return "\(weeks) week\(weeks == 1 ? "" : "s")" +
                   (days > 0 ? ", \(days) day\(days == 1 ? "" : "s")" : "")
            
        case .months:
            let months = totalDays / 30
            let remainder = totalDays % 30
            let weeks = remainder / 7
            let days = remainder % 7
            return "\(months) month\(months == 1 ? "" : "s")" +
                   (weeks > 0 ? ", \(weeks) week\(weeks == 1 ? "" : "s")" : "") +
                   (days > 0 ? ", \(days) day\(days == 1 ? "" : "s")" : "")
            
        case .years:
            let years = totalDays / 365
            let remainder = totalDays % 365
            let months = remainder / 30
            let weeks = (remainder % 30) / 7
            let days = remainder % 7
            return "\(years) year\(years == 1 ? "" : "s")" +
                   (months > 0 ? ", \(months) month\(months == 1 ? "" : "s")" : "") +
                   (weeks > 0 ? ", \(weeks) week\(weeks == 1 ? "" : "s")" : "") +
                   (days > 0 ? ", \(days) day\(days == 1 ? "" : "s")" : "")
        }
    }
}

struct Countdown: Identifiable {
    var id = UUID()
    var color: Color = Countdown.randomColor()
    var daysLeft: Int
    var name: String
    var description: String
    var emoji: String
    var priority: Priority
    var date: Date
    var photo: UIImage? = nil  // Optional photo support
    var repeatFrequency: RepeatFrequency = .none

    static func randomColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        return colors.randomElement() ?? .gray
    }
}

enum Priority: CaseIterable {
    case small
    case medium
    case large

    var displayName: String {
        switch self {
        case .small: return "Low"
        case .medium: return "Medium"
        case .large: return "High"
        }
    }
}

enum TimeDisplayMode: String, CaseIterable {
    case days = "Days"
    case weeks = "Weeks"
    case months = "Months"
    case years = "Years"
}





enum RepeatFrequency: String, CaseIterable, Identifiable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { self.rawValue }
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
