import Foundation
import UserNotifications

/// Action-item reminders (4.2.5) — head apps just store notes; Pewly nudges you to live them out.
enum NotificationService {
    static func requestAuth() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Weekly nudge to review this week's action items (e.g. Wednesday 7pm).
    static func scheduleWeeklyReview() {
        let c = UNUserNotificationCenter.current()
        c.removePendingNotificationRequests(withIdentifiers: ["pewly.weekly"])
        let content = UNMutableNotificationContent()
        content.title = "Live out Sunday's message"
        content.body = "Open Pewly to review what you noted to do this week."
        content.sound = .default
        var dc = DateComponents(); dc.weekday = 4; dc.hour = 19   // Wednesday 7pm
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        c.add(UNNotificationRequest(identifier: "pewly.weekly", content: content, trigger: trigger))
    }

    /// One-off reminder for a specific action item.
    static func remind(action text: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "From your sermon notes"
        content.body = text
        content.sound = .default
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "pewly.action.\(UUID().uuidString)", content: content, trigger: trigger))
    }
}
