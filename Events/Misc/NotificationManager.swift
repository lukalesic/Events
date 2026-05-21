import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    func requestPermissionIfNeeded(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion(granted)
                }
            case .authorized, .provisional:
                completion(true)
            default:
                completion(false)
            }
        }
    }
    
    func scheduleNotifications(for event: Event) {
        let center = UNUserNotificationCenter.current()
        
        // Remove old notifications for this event
        removeNotifications(for: event)
        
        let calendar = Calendar.current
        let eventDate = event.date
        
        // Notification 1: On the event date/time
        let onDayContent = makeContent(title: event.name, body: "Today is the day! \(event.emoji)")
        let onDayTrigger: UNNotificationTrigger
        
        if event.includesTime {
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: eventDate)
            onDayTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            var components = calendar.dateComponents([.year, .month, .day], from: eventDate)
            components.hour = 10
            components.minute = 0
            onDayTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
        
        let onDayRequest = UNNotificationRequest(
            identifier: notificationID(for: event, suffix: "onday"),
            content: onDayContent,
            trigger: onDayTrigger
        )
        center.add(onDayRequest)
        
        // Notification 2: Day before
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: eventDate) else { return }
        
        let reminderContent = makeContent(title: event.name, body: "Tomorrow! \(event.emoji)")
        let reminderTrigger: UNNotificationTrigger
        
        if event.includesTime {
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dayBefore)
            reminderTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            var components = calendar.dateComponents([.year, .month, .day], from: dayBefore)
            components.hour = 10
            components.minute = 0
            reminderTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
        
        let reminderRequest = UNNotificationRequest(
            identifier: notificationID(for: event, suffix: "daybefore"),
            content: reminderContent,
            trigger: reminderTrigger
        )
        center.add(reminderRequest)
    }
    
    func removeNotifications(for event: Event) {
        let ids = [
            notificationID(for: event, suffix: "onday"),
            notificationID(for: event, suffix: "daybefore")
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
    
    private func notificationID(for event: Event, suffix: String) -> String {
        "event_\(event.id.uuidString)_\(suffix)"
    }
    
    private func makeContent(title: String, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return content
    }
}
