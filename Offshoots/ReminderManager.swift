//
//  ReminderManager.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

import Foundation
import UserNotifications

final class ReminderManager {

    static let shared = ReminderManager()

    /// Backing key for the Settings "Follow-up Reminders" toggle
    static let enabledKey = "notificationsEnabled"

    private init() {}

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    // Normalize follow-up time to avoid firing at overnight hours
    private func normalizedFollowUpTime(from date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        // If before 7 AM → bump to 7 AM same day
        if hour < 7 {
            return calendar.date(
                bySettingHour: 7, minute: 0, second: 0,
                of: date
            )!
        }

        // If 11 PM or later → bump to 7 AM next day
        if hour >= 23 {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!
            return calendar.date(
                bySettingHour: 7, minute: 0, second: 0,
                of: nextDay
            )!
        }

        // Otherwise keep original time
        return date
    }

    // MARK: Request permission
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: Schedule reminder
    func scheduleFollowUp(for decision: Decision) {
        guard isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Review Your Decision"
        content.body = decision.title
        content.sound = .default
        content.userInfo = ["decisionID": decision.id.uuidString]

        let adjustedDate = normalizedFollowUpTime(from: decision.followUpDate)

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: adjustedDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: decision.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: Schedule secondary follow-up reminder
    func scheduleSecondaryFollowUp(for decision: Decision) {
        guard isEnabled, let secondaryDate = decision.secondaryFollowUpDate else { return }

        let content = UNMutableNotificationContent()
        content.title = "Revisit Your Decision"
        content.body = "How does \"\(decision.title)\" look now?"
        content.sound = .default
        content.userInfo = ["decisionID": decision.id.uuidString, "isSecondary": true]

        let adjustedDate = normalizedFollowUpTime(from: secondaryDate)

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: adjustedDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(decision.id.uuidString)-secondary",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: Remove reminder
    func cancelReminder(for decision: Decision) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [
                decision.id.uuidString,
                "\(decision.id.uuidString)-secondary"
            ])
    }

    // MARK: Toggle support
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Re-creates every reminder that is still in the future (used when reminders are re-enabled)
    func rescheduleAll(for decisions: [Decision]) {
        let now = Date()
        for decision in decisions {
            if decision.actual == nil, decision.followUpDate > now {
                scheduleFollowUp(for: decision)
            } else if decision.actual != nil,
                      let secondary = decision.secondaryFollowUpDate, secondary > now {
                scheduleSecondaryFollowUp(for: decision)
            }
        }
    }
}
