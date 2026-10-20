//
//  ContentView.swift
//  SyncDemo
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    let valuesManager: ValuesManager

    @State private var isScheduling = false

    private let scheduler = ReminderScheduler()
    /// Short on purpose, so the whole cycle is quick to watch.
    private let reminderDelay: TimeInterval = 10

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Current value")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(valuesManager.currentValue)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
            }

            if let pending = valuesManager.state.pendingValue,
               let fireDate = valuesManager.state.pendingFireDate {
                Label {
                    Text("\(pending) at \(fireDate.formatted(date: .omitted, time: .standard))")
                } icon: {
                    Image(systemName: "bell.badge")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                Button("Shuffle") {
                    withAnimation { valuesManager.shuffle() }
                }
                .buttonStyle(.bordered)

                Button("Remind me in \(Int(reminderDelay))s with \"\(valuesManager.nextValue)\"") {
                    let value = valuesManager.nextValue
                    // One reminder at a time: scheduling and arming finish
                    // before the button works again.
                    isScheduling = true
                    Task {
                        defer { isScheduling = false }
                        // Ask first, then compute the time, so a slow answer to
                        // the permission prompt doesn't eat the delay.
                        guard await scheduler.requestAuthorization() else { return }
                        if let fireDate = await scheduler.schedule(text: value, at: .now + reminderDelay) {
                            valuesManager.armReminder(value: value, fireDate: fireDate)
                        }
                    }
                }
                .disabled(isScheduling)
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
        }
        .padding()
        .animation(.default, value: valuesManager.state)
        .task { valuesManager.reconcileIfNeeded() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { valuesManager.reconcileIfNeeded() }
        }
    }
}

#Preview {
    ContentView(valuesManager: ValuesManager())
}
