//
//  SharedState.swift
//  Compiled into both the app and the widget extension.
//

import Foundation

/// The single source of truth the app and the widget both read, stored in the
/// App Group. It also holds what the scheduled notification promised, so every
/// surface derives what to show from the same values.
nonisolated struct SharedState: Codable, Equatable {
    static let appGroup = "group.com.example.SyncDemo"

    /// The value the app last committed.
    var currentValue: String
    /// The exact value baked into the scheduled notification's body.
    var pendingValue: String?
    /// The time the notification is scheduled for.
    var pendingFireDate: Date?

    /// The state as it should be at `date`: once the scheduled time has
    /// passed, the pending value becomes current. The widget renders this and
    /// the app commits it, so both apply the same rule.
    func resolved(at date: Date = .now) -> SharedState {
        guard let pendingValue, let pendingFireDate, pendingFireDate <= date else {
            return self
        }
        return SharedState(currentValue: pendingValue)
    }

    /// What every surface should show at `date`.
    func displayedValue(at date: Date = .now) -> String {
        resolved(at: date).currentValue
    }

    // MARK: Persistence

    /// One encoded payload under one key, so a reader never sees a mix of old
    /// and new fields.
    private static let key = "state"

    private static var defaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            preconditionFailure("App Group \(appGroup) is not configured for this target.")
        }
        return defaults
    }

    static func load() -> SharedState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SharedState.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        Self.defaults.set(data, forKey: Self.key)
    }
}
