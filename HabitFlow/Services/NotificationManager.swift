import Foundation
import UserNotifications

public final class NotificationManager: NSObject, @unchecked Sendable {
    public static let shared = NotificationManager()
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Request notification permission
    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification Authorization Error: \(error.localizedDescription)")
            }
            completion(granted)
        }
    }
    
    // Check permission status
    public func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus)
        }
    }
    
    // Schedule a reminder for a habit
    public func scheduleReminder(
        habitId: UUID,
        habitName: String,
        body: String = "Time to complete your habit!",
        hour: Int,
        minute: Int,
        weekdays: [Int] = [] // Empty array means daily, otherwise 1 = Sun, 2 = Mon ... 7 = Sat
    ) {
        let content = UNMutableNotificationContent()
        content.title = habitName
        content.body = body
        content.sound = .default
        content.userInfo = ["habitId": habitId.uuidString]
        
        let center = UNUserNotificationCenter.current()
        
        if weekdays.isEmpty {
            // Daily trigger
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "habit_reminder_\(habitId.uuidString)_daily"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule daily reminder: \(error.localizedDescription)")
                }
            }
        } else {
            // Weekly triggers for each selected day
            for weekday in weekdays {
                var dateComponents = DateComponents()
                dateComponents.weekday = weekday
                dateComponents.hour = hour
                dateComponents.minute = minute
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let identifier = "habit_reminder_\(habitId.uuidString)_weekly_\(weekday)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                center.add(request) { error in
                    if let error = error {
                        print("Failed to schedule weekly reminder for weekday \(weekday): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // Cancel reminders for a specific habit
    public func cancelReminders(for habitId: UUID) {
        let center = UNUserNotificationCenter.current()
        // We fetch and filter pending notification requests
        center.getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .filter { $0.identifier.contains(habitId.uuidString) }
                .map { $0.identifier }
            
            if !identifiersToCancel.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
            }
        }
    }
    
    // Cancel all notifications
    public func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // Snooze a notification for a specified interval in minutes
    public func snoozeNotification(request: UNNotificationRequest, intervalMinutes: Double = 15) {
        let content = request.content.mutableCopy() as! UNMutableNotificationContent
        content.title = "Snoozed: " + content.title
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalMinutes * 60, repeats: false)
        let newRequest = UNNotificationRequest(
            identifier: request.identifier + "_snoozed_" + UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(newRequest) { error in
            if let error = error {
                print("Failed to snooze notification: \(error.localizedDescription)")
            }
        }
    }
}

// Enable showing notifications even when the app is active
extension NotificationManager: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle action (e.g. Snooze)
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // User clicked notification - could open specific habit detail in future
        }
        completionHandler()
    }
}
