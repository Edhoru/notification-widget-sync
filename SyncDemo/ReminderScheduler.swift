//
//  ReminderScheduler.swift
//  SyncDemo
//

import Foundation
import UserNotifications

/// Schedules the local notification. Its content is frozen at this moment:
/// while the app is suspended or not running, iOS delivers it without running
/// any of the app's code.
struct ReminderScheduler {
    private let center = UNUserNotificationCenter.current()

    /// Asks for permission. Call this before computing a fire date, because
    /// the first prompt can stay on screen for longer than a short delay.
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) == true
    }

    /// Schedules `text` for `date` and returns the scheduled time, or nil if
    /// the date has already passed or the request was rejected.
    func schedule(text: String, at date: Date) async -> Date? {
        let fireDate = date
        guard fireDate > .now else { return nil }

        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = text
        content.sound = .default

        // Components in UTC pin the trigger to the same absolute instant as the
        // saved Date. A named local time zone isn't enough: when daylight saving
        // ends, 01:30 happens twice and the trigger picks the first one. A
        // wall-clock reminder ("every day at 9:00") would use local components.
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = utc.dateComponents(
            [.calendar, .timeZone, .year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let request = UNNotificationRequest(
            // A fixed identifier: scheduling again replaces the previous
            // reminder, matching the single pending value in SharedState.
            identifier: "reminder",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        do {
            try await center.add(request)
            return fireDate
        } catch {
            return nil
        }
    }
}
