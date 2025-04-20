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
    
    var countdowns: [CountdownVM] = []
    var selectedDisplayMode: TimeDisplayMode = .days
    
    init() {}
}

// MARK: - CRUD operations

extension CountdownViewModel {
    
    func addCountdown(_ countdown: CountdownVM) {
        countdowns.append(countdown)
    }
    
    func updateCountdown(_ updated: CountdownVM) {
        if let index = countdowns.firstIndex(where: { $0.id == updated.id }) {
            countdowns[index] = updated
        }
    }
    
    func deleteCountdown(_ countdown: CountdownVM) {
        countdowns.removeAll { $0.id == countdown.id }
    }
    
    func saveCountdown(from form: CountdownFormData, existing: CountdownVM? = nil) {
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
        
        let vm = CountdownVM(countdown: countdown)
        
        if let existing = existing {
            updateCountdown(vm)
        } else {
            addCountdown(vm)
        }
    }
}

// MARK: - Property updates

extension CountdownViewModel {
    
    func updatePriority(for id: UUID, to newPriority: Priority) {
        countdowns.first(where: { $0.id == id })?.priority = newPriority
    }
    
    func updatePhoto(for id: UUID, image: UIImage) {
        countdowns.first(where: { $0.id == id })?.photo = image
    }
    
    func updateDescription(for id: UUID, description: String) {
        countdowns.first(where: { $0.id == id })?.description = description
    }
}

// MARK: - Sharing

extension CountdownViewModel {
    
    func share(countdownVM: CountdownVM, image: UIImage?) {
        let shareText = """
        🎯 Countdown: \(countdownVM.name)
        ⏱ \(countdownVM.daysLeft) day\(countdownVM.daysLeft == 1 ? "" : "s") left \(countdownVM.emoji)
        🔔 Priority: \(countdownVM.priority.displayName)

        \(countdownVM.description)

        Shared from my Countdown App
        """
        
        var itemsToShare: [Any] = [shareText]
        
        if let shareImage = image ?? countdownVM.photo {
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

extension CountdownViewModel {
    
    func adjustedDate(for countdown: CountdownVM) -> Date {
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
    
    func formattedTimeRemaining(for countdown: CountdownVM) -> String {
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

