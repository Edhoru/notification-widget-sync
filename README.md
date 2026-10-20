# notification-widget-sync

Keep a **local notification**, your **app** and a **home screen widget** on the same content on iOS, with no server, no background tasks and no push.

All three surfaces read the same precomputed value and the same scheduled transition time. When the reminder is due, the widget switches to the value the notification carries, and the app commits that same value the next time it runs, whether the user tapped the notification, swiped it away or never saw it. iOS still decides exactly when the widget redraws and when the alert becomes visible.

Step-by-step tutorial: [One value, three surfaces](https://getcheerbit.com/exploration/one-value-three-surfaces)

## Follow along

The history is the tutorial. Each tag is the end of one step, so `git checkout step-3` puts you right after step 3, and the diff between two tags is exactly what that step adds.

| Tag | Step |
|---|---|
| `step-1` | Share one value between the app and the widget |
| `step-2` | Schedule a reminder that carries the next value (and see it fail) |
| `step-3` | Record what the notification promised |
| `step-4` | Switch the widget at the scheduled time |
| `step-5` | Reconcile by time, not by tap |
| `step-6` | Update the open app when the notification is presented |
| `step-7` | Align the saved time with the trigger |

## The problem

While your app is suspended or not running, iOS delivers a local notification without running **any of your code**, and the notification's content is frozen when you schedule it. So there's no callback where you could say "the reminder fired, update the widget". If you update things when the user taps, you're out of sync every time they dismiss the notification instead.

(When the app is in the foreground, `userNotificationCenter(_:willPresent:)` does run. Step 6 uses it.)

## The approach

Decide the future up front, write it down once, and let every surface derive what to show from the clock.

1. **Pre-compute.** When scheduling, pick the next value, bake it into the notification body and save `pendingValue` and `pendingFireDate` to the App Group.
2. **One rule.** `SharedState.resolved(at:)` turns the pending value into the current one once its scheduled time has passed. The widget renders it and the app commits it, so both apply the same rule.
3. **Date the widget entry.** The widget timeline gets a second entry dated at `pendingFireDate`, so WidgetKit can switch to the new value without the app running.
4. **Reconcile by time, not by tap.** On launch, on every return to the foreground and in `willPresent`, the app commits the resolved state once the scheduled time has passed.

```
schedule ──► SharedState { current: "Ninth", pending: "Tenth", fireDate: 10:00:00 }
                │
                ├── notification body: "Tenth"   (frozen at schedule time)
                ├── widget timeline:   [now: "Ninth", 10:00:00: "Tenth"]
                └── app:               commits "Tenth" once now >= 10:00:00
```

## Details this repo handles

- **Ask for permission before computing the date.** The first permission prompt can stay on screen longer than a short delay. The demo asks first, then computes `now + 10s`, and the scheduler rejects dates that have already passed.
- **Freeze the payload, not the "next" pointer.** If the user advances manually after scheduling, the notification still says what it said. The pending value is stored separately from the shuffle deck.
- **Only arm after scheduling succeeds.** If permission is denied or the request fails, nothing advances. (A successful `add` means the request was scheduled, not that the user saw it.)
- **One payload, one key.** The shared state is saved as a single encoded value, so the widget never reads a mix of old and new fields.
- **One reminder at a time.** The button is disabled until scheduling and arming finish.
- **Align the saved time with the trigger.** The trigger's date components stop at whole seconds, so the saved time is truncated to match the time the trigger was asked for.
- **Hop to the main actor explicitly in the delegate.** UserNotifications calls the delegate on a thread of its choosing, so the callback is `nonisolated` and moves to the main actor before touching app state.

In Cheerbit, calling `WidgetCenter` reloads off the main thread and running the notification delegate on a background executor led to a debug crash and a cold launch stuck on a white screen. That's an observed issue, not a documented API rule, but it's why this demo keeps both on the main actor.

## Limits

- **Timing is up to iOS.** WidgetKit decides when a widget actually redraws and budgets reloads, and Apple suggests spacing timeline entries minutes apart; the 10-second delay is for trying the pattern, not a timing guarantee. Focus and Scheduled Summary can also delay when the alert is visible.
- **The app doesn't redraw on its own when the time passes.** It commits the new value on launch, on foreground and when a notification is presented while it's open.
- **One pending reminder.** Scheduling again replaces it. See "Going further" for a queue.
- **Time zones.** The trigger's date components are built in UTC, so it fires at the same absolute instant as the saved `Date`, even across a daylight-saving change, when a local time like 01:30 happens twice. A wall-clock reminder ("every day at 9:00 wherever I am") needs a different policy.

## Run it

1. Open `SyncDemo.xcodeproj` in Xcode 26 or later (deployment target iOS 17).
2. Pick your team for both targets (**SyncDemo** and **NotificationWidgetExtension**).
3. Change the App Group to one you own, in three places:
   - `Shared/SharedState.swift` (`appGroup`)
   - `SyncDemo/SyncDemo.entitlements`
   - `NotificationWidgetExtension.entitlements`
4. Run, add the **Synced value** widget to the home screen, go back to the app and tap **Remind me in 10s**. Go to the home screen: when the reminder is due, the notification and the widget both show the new value, and the app shows it when you open it.

## Project layout

| File | Role |
|---|---|
| `Shared/SharedState.swift` | The App Group state and the shared rule. Compiled into both targets. |
| `SyncDemo/ValuesManager.swift` | Shuffle deck, arming, reconciling, widget reloads. |
| `SyncDemo/ReminderScheduler.swift` | Permission, then scheduling; returns the exact scheduled time. |
| `SyncDemo/SyncDemoApp.swift` | Wires the notification delegate. |
| `SyncDemo/ContentView.swift` | Demo UI. Reconciles on launch and on foreground. |
| `NotificationWidget/NotificationWidget.swift` | Timeline with the future-dated entry. |

## Going further

For a daily reminder that repeats, schedule a batch of one-shot notifications (iOS keeps up to 64 pending) and store a **queue** of `(fireDate, value)` entries instead of one pending pair. The rule stays the same: show the latest entry whose scheduled time has passed, add one widget timeline entry per future time, and reconcile to the latest due entry. That's the version running in production in [Cheerbit](https://apps.apple.com/us/app/cheerbit-daily-affirmations/id6761134932), a mood-matched affirmations app whose reminder, widget and home screen use the same scheduled line.

## License

MIT. See [LICENSE](LICENSE).
