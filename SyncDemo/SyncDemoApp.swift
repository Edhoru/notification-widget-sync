//
//  SyncDemoApp.swift
//  SyncDemo
//

import SwiftUI
import UserNotifications

@main
struct SyncDemoApp: App {
    @State private var valuesManager: ValuesManager
    private let notificationDelegate: ReminderNotificationDelegate

    init() {
        let manager = ValuesManager()
        let delegate = ReminderNotificationDelegate { manager.reconcileIfNeeded() }
        UNUserNotificationCenter.current().delegate = delegate
        _valuesManager = State(initialValue: manager)
        notificationDelegate = delegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView(valuesManager: valuesManager)
        }
    }
}

/// Shows the reminder while the app is open and reconciles at that moment, so
/// the app updates with the banner and the widget.
///
/// UserNotifications calls this delegate on a thread of its choosing, and
/// marking the class `@MainActor` would not move an incoming Objective-C
/// callback onto the main actor. So the callback is nonisolated and hops to
/// the main actor explicitly before touching app state, which ends in a
/// `WidgetCenter` reload.
nonisolated final class ReminderNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let onPresent: @MainActor @Sendable () -> Void

    init(onPresent: @escaping @MainActor @Sendable () -> Void) {
        self.onPresent = onPresent
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let onPresent = self.onPresent
        Task { @MainActor in onPresent() }
        completionHandler([.banner, .sound])
    }
}
