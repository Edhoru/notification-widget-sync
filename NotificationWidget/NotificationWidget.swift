//
//  NotificationWidget.swift
//  NotificationWidget
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ValueEntry {
        ValueEntry(date: .now, text: "First")
    }

    func getSnapshot(in context: Context, completion: @escaping (ValueEntry) -> Void) {
        let text = SharedState.load()?.currentValue ?? "First"
        completion(ValueEntry(date: .now, text: text))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ValueEntry>) -> Void) {
        guard let state = SharedState.load() else {
            completion(Timeline(entries: [ValueEntry(date: .now, text: "Open the app")], policy: .never))
            return
        }
        let entries = [ValueEntry(date: .now, text: state.currentValue)]

        // Nothing changes until the app writes new state and calls
        // reloadAllTimelines().
        completion(Timeline(entries: entries, policy: .never))
    }
}

struct ValueEntry: TimelineEntry {
    let date: Date
    let text: String
}

struct NotificationWidgetEntryView: View {
    var entry: ValueEntry

    var body: some View {
        VStack(spacing: 4) {
            Text("Value")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.text)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.6)
        }
    }
}

struct NotificationWidget: Widget {
    let kind = "NotificationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NotificationWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Synced value")
        .description("Shows the same value as the app and the reminder.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    NotificationWidget()
} timeline: {
    ValueEntry(date: .now, text: "First")
    ValueEntry(date: .now, text: "Second")
}
