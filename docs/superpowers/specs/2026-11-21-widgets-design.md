# Home Screen Widgets — Design

Date: 2026-11-21. Status: approved by Geoff, 2026-11-21.

## Intent

Give Offshoots its first Home Screen widgets, built around quick actions. The
widgets bring people back when a revisit is due, start a new log in one tap,
and make Hindsight visible to people who have not bought it.

The widgets come before the Siri starter set (TODO, "Scope the first Siri
actions"). The widget work must not create anything the Siri work will
replace. The one piece both need, an in-app router, is built here so Siri can
use it.

## Goals

- A **medium widget**: revisits due on top, a Log button and a Hindsight tile
  below.
- A **small widget**: the revisit count only.
- Every tap opens the app at the correct place, through one shared router.
- The Hindsight tile opens the Hindsight review for owners and the existing
  purchase sheet for everyone else.

## Scope update (2026-11-21)

Geoff added Shortcuts, Control Center and Lock Screen widgets to this effort.
The work runs as three separate implementation sessions, each with its own
branch. Geoff tests each one.

1. **Widgets:** this design (router, summary file, medium and small Home
   Screen widgets).
2. **Shortcuts:** the App Intents starter set (log a decision, record an
   outcome, show revisits due), Spotlight indexing and donations. It needs its
   own short design first.
3. **Control Center and Lock Screen widgets:** a "Log a decision" control and
   Lock Screen accessory widgets. They come after Shortcuts because the control
   is an App Intent. They need a short design addendum first.

## Non-goals

These are out of Stop 1 only. Stops 2 and 3 cover the first four.

- Lock Screen (accessory) widgets. Stop 3.
- A Control Center "Log a decision" control. It needs an App Intent: Stop 3.
- App Intents, Spotlight indexing, donations. Stop 2.
- Interactive widget buttons (`Button(intent:)`) and configurable widgets.
  Not planned.
- Moving the journal (`Documents/decisions.json`) to a shared container.

## Anti-goals

- Any risk to existing users' journals. The journal file does not move.
- A widget that is only an ad. The Hindsight tile sits inside a widget that is
  useful for free. There is no lock-only Hindsight widget.
- Decision titles readable on a locked phone.
- Notes, Hindsight answers or outcomes in the widget's data. Titles and dates
  only.

## Constraints

- iOS 18.6 minimum. The extension uses the same deployment target as the app.
  Nothing in this design needs the iOS 27.1 SDK.
- Review guideline 2.5.16: widgets must relate to the app's content and
  functionality. Guideline 3.1.7 keeps display ads out of widgets. A link to
  our own purchase sheet is neither problem (see Approaches).
- A widget cannot present a sheet or make a purchase. A tap only opens the app
  with a URL.
- Hindsight stays model-free. The widget shows no generated text.
- `-ReflectionUnlockOnly`, the StoreKit file and the scheme rules in CLAUDE.md
  stay as they are. The new extension target must not change the app scheme's
  Run settings.

## Approaches

How the widget gets its data. A widget runs in its own process and cannot read
the app's `Documents` folder.

- **A. Move the journal into an App Group container.** The app and the widget
  share one `decisions.json`. Rejected: every existing journal has to move on
  first launch, a failed move risks data loss, and the widget would get notes
  and answers it does not need.
- **B. The app writes a small summary file into the App Group container.**
  Picked. The journal stays where it is. The widget reads only titles, due
  dates and one Hindsight flag. Trade-off: the summary can be stale for a
  moment (for example, the app is killed between the journal save and the
  summary write). The next save fixes it, and a tap always opens the real
  data.
- **C. The widget asks the app for data through an App Intent.** Not possible:
  a widget timeline cannot call into the app.

How taps work. All taps open the app, because logging needs typing. So taps
use `widgetURL` and `Link`, not App Intents. The widget does not depend on App
Intents, and the Siri upgrades (shipping APIs now, Developer Preview in the
iOS 27.3 beta, App Store in spring 2027) cannot force a widget change.

## Design

### 1. App router (`AppRoute`)

One type for "open the app at this place". Notification taps move to it in the
same change, and the Siri open intents use it later.

```swift
enum AppRoute: Equatable {
    case log                 // Log tab
    case decision(UUID)      // Decisions tab, that decision's detail
    case readyToReview       // Decisions tab, list root (Ready to Review is on top)
    case hindsight           // owner: Insights > Hindsight review; else purchase sheet
}
```

- URL form: `offshoots://log`, `offshoots://decision/<uuid>`,
  `offshoots://revisits`, `offshoots://hindsight`. `AppRoute(url:)` parses it
  and `route.url` builds it. An unknown URL is ignored.
- `NotificationDelegate.pendingDecisionID` becomes `pendingRoute: AppRoute?`.
  `ContentView` keeps the `initial: true` handling, so a cold-launch tap is not
  lost. `.onOpenURL` sets the same pending route.
- `ContentView.handle(_ route:)` does the work:
  - `.log`: `selectedTab = .log`. The current draft stays.
  - `.decision(id)`: the existing `show(_:)`. A missing ID opens the
    Decisions list root.
  - `.readyToReview`: `selectedTab = .decisions`, `decisionsPath = []`.
  - `.hindsight`: if `HindsightAccess.canCapture`, select Insights and push
    `HindsightReviewDestination` when there is at least one entry. Otherwise
    select Insights only. If the user does not own Hindsight, present
    `HindsightPurchaseSheet` from `ContentView`. The app checks its own live
    entitlement and does not trust the widget's flag. It holds a `.hindsight`
    route until `hasResolvedOwnership` is true, so an owner never sees the
    purchase sheet during a cold launch.
- Any sheet already open is left as is. Presenting the purchase sheet over
  another sheet is the builder's call: dismiss first, or skip if it cannot be
  done cleanly.

### 2. Shared summary file

- App Group: `group.com.geoffrey.silva.Offshoots`, added to the app and the
  widget extension entitlements.
- File: `widget-summary.json` in the group container. Written atomically.
- Model (`WidgetSummary`, `Codable`, compiled into both targets):

```swift
struct WidgetSummary: Codable {
    var version = 1
    var hindsightOwned: Bool
    var items: [Item]          // sorted by dueDate, soonest first
    struct Item: Codable { var id: UUID; var title: String; var dueDate: Date }
}
```

- `items` holds every decision that is due now (no cap, so the count stays
  exact) plus the next 10 upcoming ones. (Builder-check call.) Due-ness is not stored. The widget works it
  out per timeline entry with the same day rule as
  `Decision.isReadyForReview(asOf:)`. Put that rule in the shared file so both
  sides use the same code.
- Writer (`WidgetSummaryWriter`, app only):
  - Runs at every app launch (so a user who updates and only reads still gets
    a summary), after every `DecisionStore.save()`, after `publishRestored`,
    and when the Hindsight entitlement changes.
  - Leaves `hindsightOwned` at its last written value until
    `ReflectionEntitlement.hasResolvedOwnership` is true.
  - Then calls `WidgetCenter.shared.reloadAllTimelines()`.
  - Writes nothing while `recoveryError` is set, so the widget keeps the last
    good data during a failed restore.
  - Delete All writes an empty summary.
- `hindsightOwned` is `HindsightAccess.canCapture`. A refund updates on the
  next app launch. Until then the widget can show the owner label, and a tap
  still lands on the real gate.

### 3. Widget extension (`OffshootsWidgets`)

- New Widget Extension target. Deployment target 18.6. App Group entitlement.
  No StoreKit, no FoundationModels.
- One `StaticConfiguration` per widget. `supportedFamilies`: `.systemMedium`
  and `.systemSmall`.
- Timeline provider:
  - Reads the summary. A missing or unreadable file gives the empty state.
  - Entries: now, plus the start of each day on which an upcoming item becomes
    due, up to 5 entries. Policy `.after(last entry)`, or `.atEnd` if there is
    only one.
  - Placeholder and gallery snapshot use built-in sample data, never the real
    journal.

### 4. Medium widget

```
┌──────────────────────────────────────────┐
│ ↺ Ready to Review                     2 │
│   Take the Denver job              ›     │
│   Refinance the car                ›     │
│ ──────────────────────────────────────── │
│ [ + Log a decision ]     [ ↺ Hindsight 🔒]│
└──────────────────────────────────────────┘
```

- Header: "Ready to Review" and the due count. Tapping the header or the
  widget background opens `.readyToReview`.
- Up to 2 due titles, each a `Link` to `.decision(id)`. Titles use
  `.privacySensitive()`, so iOS hides them on a locked phone.
- With nothing due: "Nothing to review today" and, if one exists, "Next:
  <title> · <weekday or date>". Without any upcoming item: "Nothing
  scheduled. Log a decision." The header uses the app's own "Ready to Review"
  label, because the count includes first reviews as well as revisits.
- Bottom row: a "Log a decision" `Link` to `.log` and a Hindsight `Link` to
  `.hindsight`.
  - Not owned: the label "Hindsight" with a small lock.
  - Owned: the label "Hindsight" without the lock.
- Uses the app palette (`.offshootPrimary`, asset colors) and
  `containerBackground`. Supports the tinted and clear Home Screen styles with
  `widgetAccentable` on the icons. Dynamic Type works as far as the family
  size allows.

### 5. Small widget

- The due count, large, and "Ready to Review". With nothing due: "Nothing
  due" and the next date, if any.
- One tap target (`widgetURL`): `.readyToReview`.
- No titles, so nothing private shows.

### How Siri plugs in later

- Siri open intents (`OpenIntent`, if any) call the same `AppRoute` handling.
  They do not get their own navigation code.
- Siri action intents (log, record an outcome, show revisits due) live in the
  app target and use `DecisionStore` directly, not the summary file. Every
  store change already refreshes the widget through the writer.
- A future Control Center "Log a decision" control is an `OpenIntent` that
  routes to `.log`.
- The Spring 2027 `@Property(authenticationPolicy:)` work applies to the
  decision entity. It does not affect the widget, which already hides titles
  on a locked phone.

## Testing

- Unit tests (Swift Testing, `OffshootsTests`):
  - `AppRoute` URL round trip and unknown URLs.
  - `WidgetSummary` building from the existing fixtures: order, all due items
    kept, the cap of 10 upcoming items, and the shared due-day rule with "now" pinned
    to 2026-09-27, as in `AnalyticsEngineTests`.
  - The writer skips the write while `recoveryError` is set.
  - Timeline entry dates for a summary with upcoming due days.
- Simulator (`verify-offshoots`): add both widgets, seed a fixture, and check
  each tap target. Check the Hindsight tile with `-HindsightLocked` (purchase
  sheet) and `-HindsightPreview` (review). Check a cold launch from a widget
  tap.
- Device check of record: the iPhone 17 (stable iOS). The Simulator does not
  prove these:
  - Locked-phone redaction: swipe right on the Lock Screen to open Today View
    with the medium widget in it. Titles must be hidden until the phone
    unlocks. (The Home Screen is never visible while locked, and StandBy shows
    only the small widget, which has no titles.)
  - The due count changes at midnight without the app opening.

## Signing and release

- App Group `group.com.geoffrey.silva.Offshoots` and widget bundle ID
  `com.geoffrey.silva.Offshoots.Widgets`. Geoff approved (2026-11-21) letting
  Xcode automatic signing create both at the first signed build.
- Release version: Geoff's call at the release pass. The release pass also
  decides whether App Store screenshots or listing text show the widgets.

## Left to the builder

- File layout for the shared files, and whether they live in a small shared
  folder or use target membership.
- Whether `offshoots://` must be registered in `CFBundleURLTypes`. Widget URLs
  reach `onOpenURL` without it. Register it only if testing shows it is
  needed.
- Exact copy within the rules above, and the widget gallery descriptions.
- Whether the summary write is debounced alongside the store's save queue.
