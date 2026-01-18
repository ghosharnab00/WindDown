import Foundation
import UserNotifications

final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Authorization
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[NotificationService] Authorization error: \(error)")
            } else {
                print("[NotificationService] Authorization granted: \(granted)")
            }
        }
    }

    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    // MARK: - Notifications
    func sendWarningNotification(minutesRemaining: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Wind Down"
        content.body = "Blocking starts in \(minutesRemaining) minutes. Open WindDown to brain dump any lingering work thoughts before you disconnect."
        content.sound = .default
        content.categoryIdentifier = "WINDDOWN_WARNING"

        let request = UNNotificationRequest(
            identifier: "winddown.warning.\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to send warning: \(error)")
            }
        }
    }

    func sendLockActivatedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "WindDown Active"
        content.body = "Work apps and websites are now blocked. Enjoy your personal time!"
        content.sound = .default
        content.categoryIdentifier = "WINDDOWN_LOCKED"

        let request = UNNotificationRequest(
            identifier: "winddown.locked.\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to send lock notification: \(error)")
            }
        }
    }

    func sendUnlockedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "WindDown Deactivated"
        content.body = "Work apps and websites are now accessible."
        content.sound = .default
        content.categoryIdentifier = "WINDDOWN_UNLOCKED"

        let request = UNNotificationRequest(
            identifier: "winddown.unlocked.\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to send unlock notification: \(error)")
            }
        }
    }

    func sendAppBlockedNotification(appName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Wind Down"
        content.body = "\(appName) is blocked outside work hours. Take a break and enjoy your personal time!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "winddown.blocked.\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to send blocked notification: \(error)")
            }
        }
    }

    func sendRitualReminderNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time for Shutdown Ritual"
        content.body = "Complete your shutdown ritual before work hours end."
        content.sound = .default
        content.categoryIdentifier = "WINDDOWN_RITUAL"

        let request = UNNotificationRequest(
            identifier: "winddown.ritual.\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to send ritual reminder: \(error)")
            }
        }
    }

    // MARK: - Scheduled Notifications
    func scheduleWarningNotification(at date: Date, minutesBefore: Int) {
        let triggerDate = date.addingTimeInterval(-Double(minutesBefore * 60))

        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to Wind Down"
        content.body = "Blocking starts in \(minutesBefore) minutes. Open WindDown to brain dump any lingering work thoughts before you disconnect."
        content.sound = .default
        content.categoryIdentifier = "WINDDOWN_WARNING"

        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "winddown.scheduled.warning",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to schedule warning: \(error)")
            }
        }
    }

    func cancelAllScheduledNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
