# Lock Screen Widgets and Control Center Control — Design

Date: 2026-11-21. Status: approved by Geoff, 2026-11-21.

## Intent

Extend Stop 1's Home Screen widgets to the Lock Screen and Control Center so
people can see at a glance whether decisions are ready to review and jump into
logging a new decision from anywhere on the phone — Control Center, a Lock
Screen corner button, or the Action Button.

This work builds directly on Stop 1 (`AppRoute`, `WidgetSummary`, and the
`OffshootsWidgets` extension) and must not create anything the upcoming
Shortcuts stop (Stop 2) has to rename, replace, or duplicate.

## Goals

- **Three Lock Screen accessory widgets** in the existing `OffshootsWidgets`
  extension, backed by the same `RevisitsProvider` and `widget-summary.json`:
  - **Circular** (`.accessoryCircular`): the due count (or a checkmark when
    clear).
  - **Inline** (`.accessoryInline`): a single line above the clock ("2 ready
    to review", or the next review date when clear).
  - **Rectangular** (`.accessoryRectangular`): "Ready to Review" with the due
    count and the soonest due decision's title (redacted while locked).
- **One Control Center control** (`LogDecisionControl`, `ControlWidgetButton`):
  opens Offshoots directly to the Log tab. Because it is a standard iOS 18
  `ControlWidget`, it also works as a Lock Screen bottom-corner button and on
  the Action Button.
- **Zero rework for Shortcuts (Stop 2)**: the control's App Intent is a minimal,
  non-discoverable open intent (`isDiscoverable = false`) that routes through
  `AppRoute.log` and never appears in the Shortcuts app.

## Non-goals

- Interactive Lock Screen buttons (`Button(intent:)`). Lock Screen accessory
  widgets have a single tap target (`widgetURL`).
- A Control Center "Revisits due" badge or toggle control. Control Center is
  for the quick "Log a decision" action; counts belong on the Lock Screen and
  Home Screen widgets.
- Any Hindsight widget on the Lock Screen or in Control Center.
- Discoverable Shortcuts actions, parameterized logging via Siri, decision
  `AppEntity`, Spotlight indexing, or donations. Those remain Stop 2
  (Shortcuts).
- Changing `widget-summary.json` schema (stays version 1) or adding a new
  extension target.

## Anti-goals

- Decision titles readable on a locked phone or Always-On Display.
- Notes, Hindsight answers, or outcomes entering `widget-summary.json` or any
  widget/control surface.
- A stray "Log a Decision" action showing up in the Shortcuts app before Stop 2
  defines the real parameterized Shortcuts actions.
- A lock-only or paywall-only Hindsight widget on the Lock Screen or Control
  Center (consistent with Stop 1 and App Review guidelines 2.5.16 and 3.1.7).

## Constraints

- **iOS 18.6 minimum.** Accessory widgets (iOS 16+) and `ControlWidget` /
  `ControlWidgetButton` / `AppIntent` with `openAppWhenRun = true` (iOS 18+)
  all ship on iOS 18.6 with no `#available` checks needed.
- **Same extension target.** Everything lives in `OffshootsWidgets`
  (`com.geoffrey.silva.Offshoots.Widgets`) and `OffshootsWidgetsBundle`. No new
  bundle ID, no new App Group, no new capabilities or entitlements, and no
  StoreKit or FoundationModels in the extension.
- **Same scheme and release rules.** No changes to `Offshoots.xcscheme`'s Run
  action, launch arguments, `Reflection.storekit`, or `selectedTab` default.
- **Hindsight stays model-free.** No generated text anywhere.

## Approaches

### Ordering vs. Shortcuts (Stop 2)

The previous plan placed Control Center and Lock Screen after Shortcuts because
a `ControlWidgetButton` requires an `AppIntent`. We evaluated whether Shortcuts
must come first or whether this work can be built now without rework:

- **Option A — Wait for Shortcuts (Stop 2) first.** Delay Lock Screen and
  Control Center until the full `AppEntity`, Spotlight index, and parameterized
  intents are designed and built. Downside: Lock Screen widgets need no intents
  at all, and the Control Center button only needs to open the Log tab — it
  does not share parameters or UI with a background "Log a Decision" shortcut.
- **Option B — Build now with a minimal, non-discoverable open intent (picked).**
  Add a single internal intent, `OpenLogDecisionIntent`, with
  `openAppWhenRun = true` and `isDiscoverable = false`.
  - Because `isDiscoverable = false`, it never appears in the Shortcuts app,
    Spotlight, or Siri suggestions.
  - When Stop 2 adds the real parameterized `LogDecisionIntent` (title,
    category, stakes, expected outcome), there is no name collision, no
    duplicate action in Shortcuts, and no migration of existing user shortcuts.
  - `OpenLogDecisionIntent` routes through `AppRoute.log`, the exact router
    Stop 2's open intents will use. Stop 2 leaves the control untouched.

### How the Control's intent hands off to `AppRoute`

Because `ControlWidgetButton` lives in `OffshootsWidgets` and executes an
`AppIntent` with `openAppWhenRun = true`, iOS runs `perform()` in the main app
process, while the intent type itself must be visible to both targets.

- **Option A — `OpenURLIntent(AppRoute.log.url)`.** Relies on LaunchServices
  opening the custom `offshoots://` scheme, which can bounce or show a
  confirmation prompt in some contexts.
- **Option B — Shared `OpenLogDecisionIntent` + `AppRoute` dispatcher (picked).**
  `OpenLogDecisionIntent` lives in `Shared/` (compiled into both `Offshoots`
  and `OffshootsWidgets`). Its `perform()` calls a tiny Foundation-only
  `@MainActor` dispatcher in `Shared/` (`AppRouteDispatcher.send(.log)`).
  `OffshootsApp.init()` registers `{ NotificationDelegate.shared.pendingRoute = $0 }`
  and drains any route queued before registration.
  - Opens Offshoots directly with no URL prompt.
  - Uses the exact same `NotificationDelegate.pendingRoute` →
    `ContentView.handle(_:)` path as notification taps and widget links, so
    cold launch, warm launch, draft preservation, and daily splash survival all
    work identically.
  - Keeps `Shared/AppRoute.swift` Foundation-only and avoids importing app-only
    types into `Shared/`.

## Design

### 1. Reusing Stop 1: router and summary file

- **Summary file (`widget-summary.json`)**: No changes to `WidgetSummary` or
  `WidgetSummaryWriter`. Lock Screen widgets read the exact same file via the
  existing `RevisitsProvider` (`TimelineProvider`). Midnight timeline refreshes
  (`refreshDates(after:)`) and `WidgetCenter.shared.reloadAllTimelines()` on
  journal changes automatically update the Lock Screen widgets alongside the
  Home Screen widgets.
- **Router (`AppRoute`)**: No new routes needed.
  - Lock Screen widgets use existing `AppRoute.readyToReview.url` and
    `AppRoute.decision(id).url` via `.widgetURL(...)`.
  - The Control Center control uses `AppRoute.log` via `AppRouteDispatcher`.
- **Home Screen widgets**: `RevisitsMediumWidget` and `RevisitsSmallWidget`
  stay untouched. Lock Screen widgets are added as a separate
  `RevisitsLockScreenWidget` in `OffshootsWidgetsBundle` (`kind: "RevisitsLockScreen"`),
  so the Home Screen widget gallery and Lock Screen widget gallery each show
  only the families meant for them.

### 2. Lock Screen widgets (`RevisitsLockScreenWidget`)

One `StaticConfiguration(kind: "RevisitsLockScreen", provider: RevisitsProvider())`
supporting `[.accessoryCircular, .accessoryInline, .accessoryRectangular]`.
Display name: `"Ready to Review"`. Description: `"See decisions ready to review
on your Lock Screen."`

All three views use `.containerBackground(.clear, for: .widget)` (standard for
Lock Screen vibrancy) and rely on system foreground styles (`.primary`,
`.secondary`) so they adapt automatically to tinted wallpapers, StandBy, and
Always-On Display.

#### 2a. Circular (`.accessoryCircular`)

```
  ╭───────╮         ╭───────╮
  │  🔔   │         │       │
  │   2   │         │   ✓   │
  ╰───────╯         ╰───────╯
  (due > 0)         (due == 0)
```

- Wrapped in `ZStack { AccessoryWidgetBackground(); ... }`.
- **Due > 0**: small `bell.badge.fill` icon (`caption2`, `.widgetAccentable()`)
  over the due count (`title3.bold().monospacedDigit()`, `.minimumScaleFactor(0.6)`).
- **Due == 0**: `checkmark` icon (`title3.weight(.semibold)`), with
  `.accessibilityLabel("Nothing ready to review")`.
- **Tap target**: `.widgetURL(AppRoute.readyToReview.url)`.
- **Privacy**: No titles. Safe while locked.

#### 2b. Inline (`.accessoryInline`)

Single line above the Lock Screen clock. SwiftUI flattens inline widgets to one
icon + text `Label`:

- **Due > 0**: `Label("\(due.count) ready to review", systemImage: "bell.badge.fill")`
  (works cleanly for both `"1 ready to review"` and `"3 ready to review"`).
- **Due == 0, upcoming exists**: `Label("Next review \(shortDay)", systemImage: "bell")`
  where `shortDay` is the abbreviated weekday within 7 days (e.g. `"Tue"`) or
  abbreviated month + day otherwise (e.g. `"Oct 18"`). No decision title.
- **Due == 0, nothing scheduled**: `Label("Nothing to review", systemImage: "checkmark")`.
- **Tap target**: `.widgetURL(AppRoute.readyToReview.url)`.
- **Privacy**: Counts and dates only; no titles. Safe while locked.

#### 2c. Rectangular (`.accessoryRectangular`)

```
┌──────────────────────────────┐    ┌──────────────────────────────┐
│ 🔔 Ready to Review         2 │    │ 🔔 Ready to Review           │
│ Take the Denver job          │    │ Nothing due today            │
│ + 1 more                     │    │ Next: Tuesday                │
└──────────────────────────────┘    └──────────────────────────────┘
  (due > 0; title redacted            (due == 0; date only,
   while phone is locked)              nothing to redact)
```

- **Header row**: `Label("Ready to Review", systemImage: "bell.badge.fill")`
  (`.font(.caption.weight(.semibold))`, `.widgetAccentable()`) with the due
  count trailing when `due.count > 0` (`.font(.caption.weight(.semibold).monospacedDigit())`).
- **Body**:
  - **Due == 1**: the due decision's title (`.font(.subheadline)`, `lineLimit(2)`,
    `.privacySensitive()`).
  - **Due > 1**: the soonest due decision's title (`.font(.subheadline)`,
    `lineLimit(1)`, `.privacySensitive()`), followed by `"+ \(due.count - 1) more"`
    (`.font(.caption)`, `.foregroundStyle(.secondary)`).
  - **Due == 0, upcoming exists**: `"Nothing due today"` (`.font(.subheadline)`)
    and `"Next: \(day)"` (`.font(.caption)`, `.foregroundStyle(.secondary)`),
    using the same weekday-within-7-days / month-and-day rule as the medium
    widget, **without** the upcoming decision's title.
  - **Due == 0, nothing scheduled**: `"Nothing due today"` and
    `"Log a decision"` (`.font(.caption)`, `.foregroundStyle(.secondary)`).
- **Tap target** (single `widgetURL`; `Link` is unsupported in accessory widgets):
  - When `due.count == 1`: `AppRoute.decision(due[0].id).url`. If the decision
    was deleted or resolved since the timeline rendered, `DecisionRoute.path(for:in:)`
    already falls back to the Decisions list root.
  - Otherwise (0 or 2+ due): `AppRoute.readyToReview.url`.
- **Privacy**: Only the due decision's title is personal, and it is marked
  `.privacySensitive()`. The header, count, and empty-state date stay legible
  while locked; the title redacts until Face ID / passcode unlocks the phone.

### 3. Control Center control (`LogDecisionControl`)

Registered alongside the widgets inside `OffshootsWidgetsBundle`:

```swift
struct LogDecisionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "LogDecisionControl") {
            ControlWidgetButton(action: OpenLogDecisionIntent()) {
                Label("Log Decision", systemImage: "plus")
            }
        }
        .displayName("Log a Decision")
        .description("Open Offshoots to log a new decision.")
    }
}
```

- **Stateless**: Uses `StaticControlConfiguration` (no value provider, does not
  read `widget-summary.json`, never needs `ControlCenter.shared.reloadAllControls()`).
- **Placements**: Automatically available in Control Center (1×1, 2×1, 2×2),
  Lock Screen bottom-corner buttons, and the Action Button on supported iPhones.
- **Intent (`Shared/OpenLogDecisionIntent.swift`)**:
  ```swift
  nonisolated struct OpenLogDecisionIntent: AppIntent {
      static let title: LocalizedStringResource = "Log a Decision"
      static let openAppWhenRun: Bool = true
      static let isDiscoverable: Bool = false

      func perform() async throws -> some IntentResult {
          await MainActor.run {
              AppRouteDispatcher.send(.log)
          }
          return .result()
      }
  }
  ```
- **Behavior on tap**:
  - Opens Offshoots (cold or warm) and switches to the Log tab (`AppRoute.log`).
  - Preserves any in-progress draft already on the Log tab (same as Stop 1).
  - Dismisses an open Hindsight purchase sheet if one was left open from an
    earlier session (already handled by `ContentView.handle(_:)`).
  - Survives the daily splash screen because `NotificationDelegate.pendingRoute`
    is consumed by `ContentView` with `initial: true`.

### 4. Privacy when the phone is locked

| Surface | Shows when locked (redaction active) | Shows when unlocked |
| --- | --- | --- |
| `.accessoryCircular` | Due count or checkmark (no titles) | Same |
| `.accessoryInline` | Count or next review date (no titles) | Same |
| `.accessoryRectangular` | "Ready to Review", count, redacted title bar (or date-only empty state) | Full soonest due title + "+ N more" |
| `LogDecisionControl` | Static "+" icon and "Log Decision" label (no data); tap requires unlock | Same; tap opens Log tab |

- Gallery previews and placeholders continue to use `WidgetSummary.sample`
  (made-up titles), never the real journal.
- Always-On Display (iPhone 17 / Pro): iOS automatically dims Lock Screen
  widgets and applies `.privacy` redaction to `.privacySensitive()` text when
  Lock Screen privacy is enabled.

### 5. Hindsight and paywall behavior

- No Hindsight widget on the Lock Screen and no Hindsight control in Control
  Center. Hindsight discovery remains a secondary tile inside the free Medium
  Home Screen widget (Stop 1) and inside the app.
- Neither `RevisitsLockScreenWidget` nor `LogDecisionControl` reads
  `summary.hindsightOwned` or routes to `.hindsight`.
- Tapping any Lock Screen widget or the Control Center control while the
  Hindsight purchase sheet is open dismisses the sheet and navigates cleanly to
  the requested destination (already implemented in `ContentView.handle(_:)`).

### 6. How Shortcuts (Stop 2) plugs in later

- `OpenLogDecisionIntent` has `isDiscoverable = false`, so Stop 2 can introduce
  a discoverable, parameterized `LogDecisionIntent` (title, category, stakes,
  expected outcome) without any duplicate or renamed action in Shortcuts.
- Stop 2's open intents (e.g., "Show Revisits Due") can call the same
  `AppRouteDispatcher.send(...)` path so all navigation continues to go through
  `AppRoute`.
- `LogDecisionControl` and `RevisitsLockScreenWidget` need zero changes when
  Stop 2 lands.

## Testing

### Unit tests (`OffshootsTests`)

- `AppRouteDispatcher`:
  - Sending a route after registration delivers it immediately.
  - Sending a route before registration queues it and delivers it once
    `register(_:)` is called (pins cold-launch safety).
  - Later sends replace an unconsumed queued route.
- Lock Screen formatting / routing helpers (if extracted into pure functions in
  `Shared/` or tested via a small helper):
  - Rectangular tap route: `.decision(first.id)` when `due.count == 1`,
    `.readyToReview` when `due.count == 0` or `due.count >= 2`.
  - Inline copy for 0 (no upcoming), 0 (upcoming), 1 due, and multiple due.
- Existing `AppRouteTests`, `WidgetSummaryTests`, and `WidgetSummaryWriterTests`
  stay green.

### Simulator checks

- Build `Offshoots` (Debug and Release) and run `scripts/archive-upload.sh --archive-only`
  to confirm automatic signing and matching versions between `Offshoots` and
  `OffshootsWidgets`.
- Inspect all three Lock Screen widget families (due = 0 empty, due = 0 with
  upcoming, due = 1, due = 2+) in SwiftUI Previews / simulator Lock Screen if
  drivable, checking truncation and legibility.
- Add `LogDecisionControl` in Control Center on the simulator and verify a tap
  opens Offshoots to the Log tab (warm launch and cold launch).

### Device checks on the iPhone 17 (stable iOS)

The Simulator does not prove Lock Screen redaction, Always-On Display, Action
Button, or midnight timeline rollover. Geoff checks these on his iPhone 17:

1. **Lock Screen redaction (`.accessoryRectangular`)**: with at least 1 due
   decision, lock the phone and check before Face ID unlocks (and on Always-On
   Display). "Ready to Review" and the count stay visible; the title must be
   redacted until unlocked. With 0 due, confirm "Nothing due today" and the
   next date show with no redacted bar.
2. **Lock Screen circular & inline widgets**: add both, check legibility over
   wallpaper and tinted Lock Screen, tap each and confirm it unlocks and opens
   Ready to Review (and that tapping rectangular with 1 due opens that decision
   directly).
3. **Control Center, Lock Screen corner button, and Action Button**:
   - Add "Log a Decision" to Control Center (1×1 and 2×1). Tap from Home Screen
     and from another app → opens Offshoots to the Log tab (preserving any
     draft, and surviving the daily splash if due).
   - Assign "Log a Decision" to a Lock Screen bottom-corner button (or Action
     Button) → tap while locked → Face ID unlocks → opens the Log tab.
4. **Shortcuts app check**: open the Shortcuts app and search "Offshoots" →
   confirm no stray "Log a Decision" shortcut appears (`isDiscoverable = false`).
5. **Combined with Stop 1's remaining iPhone 17 checks** (if tested together):
   Today View medium-widget redaction, midnight due-count rollover without
   opening the app, and first Xcode signed install creating the App Group and
   widget bundle ID.

## Signing and release

- No new bundle ID, App Group, or entitlements beyond Stop 1
  (`group.com.geoffrey.silva.Offshoots` and `com.geoffrey.silva.Offshoots.Widgets`).
- `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` continue to be checked
  together by `scripts/archive-upload.sh`.

## Left to the builder

- Whether Lock Screen views live in a new `OffshootsWidgets/RevisitsLockScreenViews.swift`
  file (recommended, keeping `RevisitsViews.swift` focused on Home Screen).
- Exact SF Symbol choice for the Control Center button (`plus` vs
  `plus.circle`) if one reads cleaner in Control Center's circular platter.
- Updating `CLAUDE.md`'s `Shared/` note to mention that
  `OpenLogDecisionIntent.swift` imports `AppIntents` while `AppRoute.swift` and
  `WidgetSummary.swift` stay Foundation-only.
