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
    //MARK: Essential CRUD operations
    
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
    
    func saveCountdown(from form: CountdownFormData, existing: Countdown? = nil) {
        let today = Calendar.current.startOfDay(for: .now)
        let target = Calendar.current.startOfDay(for: form.date)
        let newDaysLeft = Calendar.current.dateComponents([.day], from: today, to: target).day ?? 0

        let finalEmoji = form.emoji.isEmpty ? "📅" : form.emoji

        let countdown = Countdown(
            id: existing?.id ?? UUID(),
            color: form.color,
            daysLeft: newDaysLeft,
            name: form.name,
            description: form.description,
            emoji: finalEmoji,
            priority: form.priority,
            date: form.date,
            photo: form.photo,
            repeatFrequency: form.repeatFrequency
        )

        if existing != nil {
            updateCountdown(countdown)
        } else {
            addCountdown(countdown)
        }
    }
}

extension CountdownViewModel {
    //MARK: Secondary characteristics - priority, image
    
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
}

extension CountdownViewModel {
    //MARK: Calculating dates
    
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

