//
//  SharedState.swift
//  Compiled into both the app and the widget extension.
//

import Foundation

/// The state the app and the widget both read, stored in the App Group.
nonisolated struct SharedState: Codable, Equatable {
    static let appGroup = "group.com.example.SyncDemo"

    /// The value the app last committed.
    var currentValue: String

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
