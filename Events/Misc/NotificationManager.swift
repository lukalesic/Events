import Foundation
import UserNotifications
import UIKit

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    /// Published event ID when user taps a notification
    var tappedEventID: UUID?
    var onNotificationTapped: ((UUID) -> Void)?
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
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
        
        removeNotifications(for: event)
        
        let calendar = Calendar.current
        let eventDate = event.date
        let defaultHour = UserDefaults.standard.defaultNotificationHour
        let defaultMinute = UserDefaults.standard.defaultNotificationMinute
        
        // Notification 1: On the event date/time
        let onDayContent = makeContent(title: event.name, body: "Today is the day! \(event.emoji)", photoData: event.photoData, eventID: event.id)
        let onDayTrigger: UNNotificationTrigger
        
        if event.includesTime {
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: eventDate)
            onDayTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            var components = calendar.dateComponents([.year, .month, .day], from: eventDate)
            components.hour = defaultHour
            components.minute = defaultMinute
            onDayTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
        
        let onDayRequest = UNNotificationRequest(
            identifier: notificationID(for: event, suffix: "onday"),
            content: onDayContent,
            trigger: onDayTrigger
        )
        center.add(onDayRequest)
        
        // Notification 2: Day before (if enabled)
        if UserDefaults.standard.remind1DayBefore {
            guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: eventDate) else { return }
            
            let reminderContent = makeContent(title: event.name, body: "Tomorrow! \(event.emoji)", photoData: event.photoData, eventID: event.id)
            let reminderTrigger: UNNotificationTrigger
            
            if event.includesTime {
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dayBefore)
                reminderTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            } else {
                var components = calendar.dateComponents([.year, .month, .day], from: dayBefore)
                components.hour = defaultHour
                components.minute = defaultMinute
                reminderTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            }
            
            let reminderRequest = UNNotificationRequest(
                identifier: notificationID(for: event, suffix: "daybefore"),
                content: reminderContent,
                trigger: reminderTrigger
            )
            center.add(reminderRequest)
        }
        
        // Notification 3: 3 days before (if enabled)
        if UserDefaults.standard.remind3DaysBefore {
            guard let threeDaysBefore = calendar.date(byAdding: .day, value: -3, to: eventDate) else { return }
            
            let content = makeContent(title: event.name, body: "3 days to go! \(event.emoji)", photoData: event.photoData, eventID: event.id)
            let trigger: UNNotificationTrigger
            
            if event.includesTime {
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: threeDaysBefore)
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            } else {
                var components = calendar.dateComponents([.year, .month, .day], from: threeDaysBefore)
                components.hour = defaultHour
                components.minute = defaultMinute
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            }
            
            let request = UNNotificationRequest(
                identifier: notificationID(for: event, suffix: "3daysbefore"),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
    
    func removeNotifications(for event: Event) {
        let ids = [
            notificationID(for: event, suffix: "onday"),
            notificationID(for: event, suffix: "daybefore"),
            notificationID(for: event, suffix: "3daysbefore")
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let eventIDString = userInfo["eventID"] as? String,
           let eventID = UUID(uuidString: eventIDString) {
            DispatchQueue.main.async {
                self.tappedEventID = eventID
                self.onNotificationTapped?(eventID)
            }
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // MARK: - Private
    
    private func notificationID(for event: Event, suffix: String) -> String {
        "event_\(event.id.uuidString)_\(suffix)"
    }
    
    private func makeContent(title: String, body: String, photoData: Data?, eventID: UUID) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["eventID": eventID.uuidString]
        
        if let photoData, let attachment = imageAttachment(from: photoData) {
            content.attachments = [attachment]
        }
        
        return content
    }
    
    private func imageAttachment(from data: Data) -> UNNotificationAttachment? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString + ".jpg")
        
        do {
            try data.write(to: fileURL)
            return try UNNotificationAttachment(identifier: UUID().uuidString, url: fileURL, options: nil)
        } catch {
            return nil
        }
    }
}
