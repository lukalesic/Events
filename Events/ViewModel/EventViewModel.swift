//
//  CountdownViewModel.swift
//  Events
//
//  Created by Luka Lešić on 23.03.25.
//

import Foundation
import SwiftUI
import Observation
import SwiftData

@Observable
class EventViewModel {
    
    var selectedDisplayMode: TimeDisplayMode = .days
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchCountdowns() -> [Countdown] {
        let descriptor = FetchDescriptor<Countdown>()
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch countdowns: \(error)")
            return []
        }
    }
}

// MARK: - CRUD operations
extension EventViewModel {
    
    func addCountdown(_ countdown: Countdown) {
        modelContext.insert(countdown)
        saveContext()
    }
    
    func updateCountdown(_ countdown: Countdown) {
        // No need to explicitly update - SwiftData tracks changes to managed objects
        saveContext()
    }
    
    func delete(_ countdown: Countdown) {
        modelContext.delete(countdown)
        saveContext()
    }
    
    func save(from form: EventFormData, existing: Countdown? = nil) {
        let today = Calendar.current.startOfDay(for: .now)
        let target = Calendar.current.startOfDay(for: form.date)
        let newDaysLeft = Calendar.current.dateComponents([.day], from: today, to: target).day ?? 0
        let finalEmoji = form.emoji.isEmpty ? "📅" : form.emoji
        
        if let existingCountdown = existing {
            // Update existing countdown
            existingCountdown.color = form.color
            existingCountdown.daysLeft = newDaysLeft
            existingCountdown.name = form.name
            existingCountdown.descriptionText = form.description
            existingCountdown.emoji = finalEmoji
            existingCountdown.priority = form.priority
            existingCountdown.date = form.date
            existingCountdown.photo = form.photo
            existingCountdown.repeatFrequency = form.repeatFrequency
        } else {
            // Create new countdown
            let countdown = Countdown()
            countdown.id = UUID()
            countdown.color = form.color
            countdown.daysLeft = newDaysLeft
            countdown.name = form.name
            countdown.descriptionText = form.description
            countdown.emoji = finalEmoji
            countdown.priority = form.priority
            countdown.date = form.date
            countdown.photo = form.photo
            countdown.repeatFrequency = form.repeatFrequency
            
            addCountdown(countdown)
        }
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func deleteAllPastCountdowns() {
        let today = Calendar.current.startOfDay(for: .now)
        
        let descriptor = FetchDescriptor<Countdown>(
            predicate: #Predicate { $0.date < today }
        )
        
        do {
            let pastCountdowns = try modelContext.fetch(descriptor)
            for countdown in pastCountdowns {
                modelContext.delete(countdown)
            }
            saveContext()
        } catch {
            print("Failed to delete past countdowns: \(error)")
        }
    }
}

// MARK: - Property updates
extension EventViewModel {
    
    func updatePriority(for countdown: Countdown, to newPriority: EventPriority) {
        countdown.priority = newPriority
        saveContext()
    }
    
    func updatePhoto(for countdown: Countdown, image: UIImage) {
        countdown.photo = image
        saveContext()
    }
    
    func updateDescription(for countdown: Countdown, description: String) {
        countdown.descriptionText = description
        saveContext()
    }
}

// MARK: - Sharing
extension EventViewModel {
    
    func share(event: Countdown, image: UIImage?) {
        let shareText = """
        🎯 Countdown: \(event.name)
        ⏱ \(event.daysLeft) day\(event.daysLeft == 1 ? "" : "s") left \(event.emoji)
        🔔 Priority: \(event.priority.rawValue.capitalized)

        \(event.descriptionText)

        Shared from my Countdown App
        """
        
        var itemsToShare: [Any] = [shareText]
        
        if let shareImage = image ?? event.photo {
            itemsToShare.append(shareImage)
        }
        
        let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        topVC.present(activityVC, animated: true)
    }
}

// MARK: - Date handling
extension EventViewModel {
    
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

        if totalDays == 0 {
            return "Today"
        } else if totalDays < 0 {
            return formattedPastTime(from: abs(totalDays))
        }

        switch selectedDisplayMode {
        case .days:
            return "\(totalDays) day\(totalDays == 1 ? "" : "s") left"
        case .weeks:
            let weeks = totalDays / 7
            let days = totalDays % 7
            return "\(weeks) week\(weeks == 1 ? "" : "s")" +
                   (days > 0 ? ", \(days) day\(days == 1 ? "" : "s") left" : "")
        case .months:
            let months = totalDays / 30
            let remainder = totalDays % 30
            let weeks = remainder / 7
            let days = remainder % 7
            return "\(months) month\(months == 1 ? "" : "s")" +
                   (weeks > 0 ? ", \(weeks) week\(weeks == 1 ? "" : "s")" : "") +
                   (days > 0 ? ", \(days) day\(days == 1 ? "" : "s") left" : "")
        case .years:
            let years = totalDays / 365
            let remainder = totalDays % 365
            let months = remainder / 30
            let weeks = (remainder % 30) / 7
            let days = remainder % 7
            return "\(years) year\(years == 1 ? "" : "s")" +
                   (months > 0 ? ", \(months) month\(months == 1 ? "" : "s")" : "") +
                   (weeks > 0 ? ", \(weeks) week\(weeks == 1 ? "" : "s")" : "") +
                   (days > 0 ? ", \(days) day\(days == 1 ? "" : "s") left" : "")
        }
    }
    
    private func formattedPastTime(from totalDays: Int) -> String {
        switch selectedDisplayMode {
        case .days:
            return "\(totalDays) day\(totalDays == 1 ? "" : "s") ago"
        case .weeks:
            let weeks = totalDays / 7
            let days = totalDays % 7
            return "\(weeks) week\(weeks == 1 ? "" : "s")" +
                   (days > 0 ? ", \(days) day\(days == 1 ? "" : "s")" : "") + " ago"
        case .months:
            let months = totalDays / 30
            let remainder = totalDays % 30
            let weeks = remainder / 7
            let days = remainder % 7
            return "\(months) month\(months == 1 ? "" : "s")" +
                   (weeks > 0 ? ", \(weeks) week\(weeks == 1 ? "" : "s")" : "") +
                   (days > 0 ? ", \(days) day\(days == 1 ? "" : "s")" : "") + " ago"
        case .years:
            let years = totalDays / 365
            let remainder = totalDays % 365
            let months = remainder / 30
            let weeks = (remainder % 30) / 7
            let days = remainder % 7
            return "\(years) year\(years == 1 ? "" : "s")" +
                   (months > 0 ? ", \(months) month\(months == 1 ? "" : "s")" : "") +
                   (weeks > 0 ? ", \(weeks) week\(weeks == 1 ? "" : "s")" : "") +
                   (days > 0 ? ", \(days) day\(days == 1 ? "" : "s")" : "") + " ago"
        }
    }
}
