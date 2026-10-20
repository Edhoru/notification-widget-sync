//
//  ValuesManager.swift
//  SyncDemo
//

import Foundation
import Observation
import WidgetKit

/// Owns the value shown in the app and keeps it in sync with the scheduled
/// notification and the widget through `SharedState`.
///
/// Main-actor isolated (the target's default isolation), which also keeps
/// `WidgetCenter` reloads on the main thread.
@Observable
final class ValuesManager {
    let values = [
        "First", "Second", "Third", "Fourth", "Fifth",
        "Sixth", "Seventh", "Eighth", "Ninth", "Tenth",
    ]

    private(set) var state: SharedState
    /// The value a new reminder would carry: the head of the shuffled deck.
    private(set) var nextValue: String

    /// Upcoming values in shuffled order, so nothing repeats until every value
    /// has been shown. App-only, so it lives in standard defaults.
    private var deck: [String]

    var currentValue: String { state.currentValue }

    init() {
        let restoredState: SharedState
        let restoredDeck: [String]
        if let saved = SharedState.load(),
           let savedDeck = UserDefaults.standard.stringArray(forKey: "deck"), !savedDeck.isEmpty {
            restoredState = saved
            restoredDeck = savedDeck
        } else {
            var fresh = values.shuffled()
            restoredState = SharedState(currentValue: fresh.removeFirst())
            restoredDeck = fresh
        }
        state = restoredState
        deck = restoredDeck
        nextValue = restoredDeck[0]
        save()
    }

    /// Manual advance: next becomes current. A pending reminder is untouched,
    /// because its value is already frozen in the notification body.
    func shuffle() {
        state.currentValue = deck.removeFirst()
        refillIfNeeded()
        nextValue = deck[0]
        save()
    }

    /// Records the value that was just baked into a scheduled notification.
    /// Call it only after scheduling succeeded, so the app and widget never
    /// advance for a reminder that was never scheduled.
    func armReminder(value: String, fireDate: Date) {
        state.pendingValue = value
        state.pendingFireDate = fireDate
        // Reserve the frozen value so it isn't handed out again as the next one.
        if deck.first == value {
            deck.removeFirst()
            refillIfNeeded()
            nextValue = deck[0]
        }
        save()
    }

    /// Reshuffles a fresh round when the deck runs low, avoiding an immediate
    /// repeat across the shuffle boundary.
    private func refillIfNeeded() {
        guard deck.count < 2 else { return }
        var round = values.shuffled()
        if round.first == (deck.last ?? state.currentValue), round.count > 1 {
            round.swapAt(0, 1)
        }
        deck.append(contentsOf: round)
    }

    private func save() {
        state.save()
        UserDefaults.standard.set(deck, forKey: "deck")
        // Tell the widget to rebuild its timeline from the new shared state.
        WidgetCenter.shared.reloadAllTimelines()
    }
}
