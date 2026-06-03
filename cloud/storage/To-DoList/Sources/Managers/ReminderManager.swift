import Foundation
import UserNotifications

/// Manages scheduling and canceling local notifications for todo reminders.
///
/// Note: UI must request notification authorization. This manager intentionally does not
/// auto-request permission to keep side effects explicit.
public protocol ReminderManaging {
    func scheduleReminder(for item: TodoItem) async throws
    func cancelReminder(for itemID: TodoItem.ID) async
}

public final class ReminderManager: ReminderManaging {

    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func scheduleReminder(for item: TodoItem) async throws {
        guard let reminderDate = item.reminderDate else { return }

        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = item.title
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: item.id),
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    public func cancelReminder(for itemID: TodoItem.ID) async {
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier(for: itemID)])
    }

    private func notificationIdentifier(for id: TodoItem.ID) -> String {
        "todo.reminder.\(id.uuidString)"
    }
}
