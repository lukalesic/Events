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
import EventKit
import WidgetKit

@Observable
class EventViewModel {
    
    var selectedDisplayMode: TimeDisplayMode = .days
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchCountdowns() -> [Event] {
        let descriptor = FetchDescriptor<Event>()
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
    
    func addCountdown(_ countdown: Event) {
        modelContext.insert(countdown)
        saveContext()
    }
    
    func updateCountdown(_ countdown: Event) {
        saveContext()
        reloadWidget()
    }
    
    func delete(_ countdown: Event) {
        modelContext.delete(countdown)
        saveContext()
    }
    
    func save(from form: EventFormData, existing: Event? = nil) {
        let today = Calendar.current.startOfDay(for: .now)
        let target = Calendar.current.startOfDay(for: form.date)
        let newDaysLeft = Calendar.current.dateComponents([.day], from: today, to: target).day ?? 0
        let finalEmoji = form.emoji.isEmpty ? "📅" : form.emoji
        
        if let existingEvent = existing {
            // Update existing countdown
            
            let nameChanged = existingEvent.name != form.name
            let dateChanged = existingEvent.date != form.date

            if nameChanged || dateChanged {
                resetCalendarState(for: existingEvent)
            }
            
            existingEvent.color = form.color
            existingEvent.daysLeft = newDaysLeft
            existingEvent.name = form.name
            existingEvent.descriptionText = form.description
            existingEvent.emoji = finalEmoji
            existingEvent.priority = form.priority
            existingEvent.includesTime = form.includesTime
            existingEvent.date = form.date
            existingEvent.photo = form.photo
            existingEvent.repeatFrequency = form.repeatFrequency
            reloadWidget()
        } else {
            // Create new countdown
            let event = Event()
            event.id = UUID()
            event.color = form.color
            event.daysLeft = newDaysLeft
            event.name = form.name
            event.descriptionText = form.description
            event.emoji = finalEmoji
            event.priority = form.priority
            event.date = form.date
            event.includesTime = form.includesTime
            event.photo = form.photo
            event.repeatFrequency = form.repeatFrequency

            addCountdown(event)
        }
    }
    
    private func resetCalendarState(for event: Event) {
        event.isAddedToCalendar = false
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
            reloadWidget()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func deleteAllPastCountdowns() {
        let today = Calendar.current.startOfDay(for: .now)
        
        let descriptor = FetchDescriptor<Event>(
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
    
    private func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Property updates
extension EventViewModel {
    
    func updatePriority(for countdown: Event, to newPriority: EventPriority) {
        countdown.priority = newPriority
        saveContext()
    }
    
    func updatePhoto(for countdown: Event, image: UIImage) {
        countdown.photo = image
        saveContext()
    }
    
    func updateDescription(for countdown: Event, description: String) {
        countdown.descriptionText = description
        saveContext()
    }
}

// MARK: - Sharing
extension EventViewModel {
    
    func share(event: Event, image: UIImage?) {
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
    
    func adjustedDate(for countdown: Event) -> Date {
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
        
        return countdown.includesTime ? nextDate : Calendar.current.startOfDay(for: nextDate)
    }
        
    func formattedTimeRemaining(for countdown: Event) -> String {
        let now = Calendar.current.startOfDay(for: .now)
        let target = Calendar.current.startOfDay(for: adjustedDate(for: countdown))
        let totalDays = Calendar.current.dateComponents([.day], from: now, to: target).day ?? 0

        if totalDays == 0 {
            return "Today"
        } else if totalDays < 0 {
            // Handle past events
            let daysAgo = abs(totalDays)
            switch selectedDisplayMode {
            case .days:
                return "\(daysAgo) day\(daysAgo == 1 ? "" : "s") ago"
            case .automatic:
                return breakdownTime(totalDays: daysAgo) + " ago"
            }
            
        } else {
            // Handle future events
            switch selectedDisplayMode {
            case .days:
                return "\(totalDays) day\(totalDays == 1 ? "" : "s") left"
            case .automatic:
                return breakdownTime(totalDays: totalDays) + " left"
            }
        }
    }
    
    private func breakdownTime(totalDays: Int) -> String {
        var days = totalDays
        let years = days / 365
        days %= 365
        let months = days / 30
        days %= 30
        let weeks = days / 7
        days %= 7

        var parts: [String] = []

        if years > 0 {
            parts.append("\(years) year\(years == 1 ? "" : "s")")
        }
        if months > 0 {
            parts.append("\(months) month\(months == 1 ? "" : "s")")
        }
        if weeks > 0 {
            parts.append("\(weeks) week\(weeks == 1 ? "" : "s")")
        }
        if days > 0 {
            parts.append("\(days) day\(days == 1 ? "" : "s")")
        }

        return parts.joined(separator: ", ")
    }
    
    func addToCalendar(_ event: Event, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        EventKitManager.shared.add(event: event) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    onSuccess()
                case .failure(let error):
                    print("Failed to add event to calendar:", error.localizedDescription)
                    onFailure()
                }
            }
        }
    }
}

class EventKitManager {
    static let shared = EventKitManager()
    private let eventStore = EKEventStore()

    enum CalendarError: Error {
        case accessDenied
        case saveFailed
    }

    func add(event: Event, completion: @escaping (Result<Void, Error>) -> Void) {
        eventStore.requestAccess(to: .event) { granted, error in
            if granted {
                let ekEvent = EKEvent(eventStore: self.eventStore)
                ekEvent.title = event.name
                ekEvent.notes = event.descriptionText

                let calendar = Calendar.current

                if event.includesTime {
                    ekEvent.startDate = event.date
                } else {
                    ekEvent.startDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: event.date) ?? event.date
                }

                ekEvent.endDate = ekEvent.startDate.addingTimeInterval(60 * 60)
                ekEvent.calendar = self.eventStore.defaultCalendarForNewEvents

                do {
                    try self.eventStore.save(ekEvent, span: .thisEvent)
                    completion(.success(()))
                } catch {
                    completion(.failure(CalendarError.saveFailed))
                }
            } else {
                completion(.failure(CalendarError.accessDenied))
            }
        }
    }
}
