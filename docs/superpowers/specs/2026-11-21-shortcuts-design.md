# Shortcuts and Siri Starter Set — Design

Date: 2026-11-21. Status: draft, awaiting Geoff's approval.

## Intent

Give Offshoots its first Shortcuts and Siri actions — logging a decision,
recording an outcome or revisit, and checking which decisions are ready to
review — along with Spotlight search for decisions and in-app intent donations.

Every intent, entity, and parameter carries clear natural-language descriptions
from day one so the starter set is ready for Apple's Siri AI tool use without a
rewrite later, while keeping personal journal notes and paid Hindsight answers
private and out of Siri and Spotlight.

## Goals

- **Three discoverable App Intents** in the Shortcuts app and Siri:
  1. **Log a Decision** (`LogDecisionIntent`): create a pending decision with a
     title, expected outcome, optional category, stakes, review date, and note.
  2. **Record Outcome** (`RecordOutcomeIntent`): mark the first outcome on a
     pending decision, or add a revisit on an already-marked decision, with an
     optional note and next revisit date.
  3. **Show Decisions Ready to Review** (`ShowRevisitsDueIntent`): return the
     decisions currently due (optionally filtered by category) with a spoken
     summary.
- **`DecisionEntity` (`AppEntity` + `IndexedEntity`)**:
  - Lets Shortcuts pass decisions between actions and lets Spotlight find
    decisions by title and category.
  - Tapping a Spotlight result or opening a decision from Shortcuts routes
    through `AppRoute.decision(id)` (`OpenDecisionIntent`), adding no duplicate
    navigation code.
- **App Shortcuts (`OffshootsShortcuts`)**: ready-to-use Siri phrases that work
  immediately after install without manual setup in Shortcuts.
- **Intent donations**: donate `LogDecisionIntent` and `RecordOutcomeIntent`
  when the user logs a decision or marks an outcome/revisit in the app.
- **Zero rework to Stop 1 or Stop 3**: `LogDecisionControl`'s internal
  `OpenLogDecisionIntent` (`isDiscoverable = false`) and all Home Screen / Lock
  Screen widgets stay untouched.

## Non-goals

- Capturing, reading, or indexing **Hindsight answers** via Siri, Shortcuts, or
  Spotlight (DECISIONS 2026-10-28: Hindsight stays in-app and model-free).
- Exposing decision notes, reflection prose, or revisit notes in `DecisionEntity`
  properties, Spotlight attributes, or spoken dialogs.
- Deleting decisions, importing/exporting backups, or changing Settings via
  Shortcuts.
- Any AI / Foundation Models integration (dropped 2026-11-21).
- Changing `decisions.json` or `widget-summary.json` file formats.

## Anti-goals

- Personal decision details or journal notes leaking onto a locked phone via
  Siri or Spotlight.
- Duplicate `"Log a Decision"` actions in Shortcuts (already prevented by
  `OpenLogDecisionIntent.isDiscoverable = false`).
- Writing to `decisions.json` while a failed restore needs recovery
  (`startupError != nil || store.recoveryError != nil`).
- Separate navigation state for intents — every open action must go through
  `AppRoute` / `AppRouteDispatcher`.

## Constraints

- **iOS 18.6 minimum.** `AppIntents`, `AppEntity`, `IndexedEntity`,
  `EntityStringQuery`, `AppShortcutsProvider`, `AppDependencyManager`,
  `IntentDonationManager`, and `IntentAuthenticationPolicy` all ship on
  iOS 18.6 with no `#available` checks needed.
- **App target only for the new intents.** All Shortcuts intents,
  `DecisionEntity`, Spotlight indexing, and `OffshootsShortcuts` live in the
  `Offshoots` app target (`Offshoots/Shortcuts/`), where `DecisionStore` and
  `Decision` live. `OffshootsWidgets` keeps only `OpenLogDecisionIntent` from
  `Shared/`.
- **Widget sync stays automatic.** Because intents mutate `DecisionStore`, its
  existing save/revision path (and `WidgetSummaryWriter`) automatically keeps
  Home Screen and Lock Screen widgets in sync — we just need the writer to
  trigger on store saves even when the UI scene is not active (see Design §5).
- **Same scheme and release rules.** No changes to `Offshoots.xcscheme`'s Run
  action, launch arguments, `Reflection.storekit`, or `selectedTab` default.

## Approaches

### How intents access `DecisionStore` and refresh widgets

An App Intent with `openAppWhenRun = false` runs in the app process, possibly in
the background when no SwiftUI scene (`WindowGroup`) is mounted.

- **Option A — Read/write `decisions.json` directly inside each intent.**
  Rejected: duplicates `DecisionStore`'s serialization, bypasses reminder
  scheduling (`ReminderManager`), risks racing with an open app's in-memory
  store, and skips `WidgetSummaryWriter`.
- **Option B — Register `DecisionStore` and `WidgetSummaryWriter` via `AppDependencyManager` in `OffshootsApp.init()` (picked).**
  `OffshootsApp.init()` already runs once per process launch, performs
  `JournalDataCoordinator.recover`, creates the single `DecisionStore` and
  `WidgetSummaryWriter`, and registers `AppRouteDispatcher`. Registering the
  store (or a small `@MainActor` `ShortcutsService` holding the store, writer,
  and recovery-blocked flag) with `AppDependencyManager.shared.add(dependency:)`
  means:
  - Background intents and foreground UI share the exact same `DecisionStore`
    instance.
  - Recovery blocking is enforced identically everywhere.
  - Reminders are scheduled/cancelled through `DecisionStore` as required by
    `CLAUDE.md`.
  - Calling `widgetSummary.update(decisions:blocked:)` after a background intent
    mutation keeps Home Screen and Lock Screen widgets fresh even when
    `WindowGroup`'s `.onChange(of: store.revision)` is not active.

## Design

### 1. Shared AppEnums (`Offshoots/Shortcuts/DecisionAppEnums.swift`)

Thin `AppEnum` wrappers (or conformances) mapping 1:1 to `Decision`'s types:

- **`DecisionOutcomeAppEnum`**:
  - Cases: `.veryBad` ("Very Bad"), `.bad` ("Bad"), `.neutral` ("Neutral"),
    `.good` ("Good"), `.veryGood` ("Great") — matching `DecisionOutcome.shortLabel`.
- **`DecisionCategoryAppEnum`**:
  - Cases: `.work` ("Work"), `.money` ("Money"), `.health` ("Health"),
    `.relationships` ("Relationships"), `.home` ("Home"), `.other` ("Other").
- **`DecisionStakesAppEnum`**:
  - Cases: `.low` ("Low"), `.medium` ("Medium"), `.high` ("High").

### 2. `DecisionEntity` and Spotlight indexing (`Offshoots/Shortcuts/DecisionEntity.swift`)

```swift
struct DecisionEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("Decision"),
        numericFormat: "\(placeholder: .int) decisions"
    )
    static let defaultQuery = DecisionEntityQuery()

    let id: UUID
    @Property(title: "Title") var title: String
    @Property(title: "Category") var category: DecisionCategoryAppEnum
    @Property(title: "Stakes") var stakes: DecisionStakesAppEnum
    @Property(title: "Expected Outcome") var expected: DecisionOutcomeAppEnum
    @Property(title: "Current Outcome") var currentOutcome: DecisionOutcomeAppEnum?
    @Property(title: "Next Review Date") var nextReviewDate: Date?
    @Property(title: "Ready to Review") var isReadyForReview: Bool
}
```

- **Display representation**: `title` as title, subtitle `"<Category> · Ready to review"` when due, else `"<Category> · <currentOutcome or Expected <expected>>"`.
- **Privacy boundary**: `notes`, `reflection`, revisit notes, and `hindsight`
  answers are **not** properties on `DecisionEntity` and are **never** written
  to Spotlight (`attributeSet`).
- **Query (`DecisionEntityQuery: EntityStringQuery`)**:
  - `entities(for identifiers: [UUID])`: looks up matching decisions in
    `DecisionStore`.
  - `entities(matching string: String)`: case-insensitive substring match on
    `title` and `category` display name.
  - `suggestedEntities()`: returns decisions ready to review first (soonest
    first), followed by the most recent pending decisions (capped at 10).
- **Spotlight indexing (`DecisionSpotlightIndexer`)**:
  - Uses `CSSearchableIndex.default().indexAppEntities(...)` on create, update,
    resolve, revisit, and import; `deleteAppEntities(identifiedBy:ofType:)` on
    delete; `deleteAllAppEntities(ofType:)` on Delete All.
  - Also performs a one-time / startup sync on launch (when not blocked by
    recovery) so existing journals become searchable after updating to this
    version.
  - Opening a Spotlight hit invokes `OpenDecisionIntent` (`OpenIntent`), which
    calls `AppRouteDispatcher.shared.send(.decision(target.id))`.

### 3. Discoverable App Intents (`Offshoots/Shortcuts/`)

All three intents set:
- `static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication`
  so Siri/Shortcuts requires unlocking the phone before reading or modifying
  personal decisions.
- Rich `static let description = IntentDescription(...)` with a `categoryName`
  and clear `ParameterSummary` so they read naturally in the Shortcuts editor
  and are ready for Siri AI tool selection.

#### 3a. `LogDecisionIntent`

- **Title**: `"Log a Decision"`
- **Description**: `"Logs a new decision in Offshoots with your predicted outcome and schedules a follow-up review reminder."`
- **Parameters**:
  - `title: String` (required) — `"What decision are you making?"`
  - `expected: DecisionOutcomeAppEnum` (required) — `"How do you expect it to turn out?"`
  - `category: DecisionCategoryAppEnum` (default `.other`) — `"Category"`
  - `stakes: DecisionStakesAppEnum` (default `.medium`) — `"Stakes"`
  - `reviewDate: Date?` (optional, default tomorrow at the current time of day
    via `ReviewDatePreset.tomorrow.date(from:)`) — `"When should Offshoots remind you to review it?"`
  - `notes: String?` (optional) — `"Optional context note saved only inside Offshoots."`
- **Validation**:
  - Reject empty/whitespace-only `title` with a clear error.
  - Reject a `reviewDate` in the past (before `Calendar.current.startOfDay(for: .now)`),
    matching the app's own rule (DECISIONS 2026-09-26).
  - Refuse if `DecisionStore` is blocked by an unresolved restore.
- **Effect**:
  - Calls `store.createDecision(...)` (saves journal, schedules reminder if
    enabled).
  - Refreshes `WidgetSummaryWriter`, indexes the new entity in Spotlight.
  - Returns the created `DecisionEntity` + dialog:
    `"Logged \"<title>\" in <Category>. Review set for <formatted date>."`

#### 3b. `RecordOutcomeIntent`

- **Title**: `"Record Outcome"`
- **Description**: `"Records how a decision actually turned out, or adds a new revisit rating to an already-marked decision."`
- **Parameters**:
  - `decision: DecisionEntity` (required) — `"Which decision?"`
  - `outcome: DecisionOutcomeAppEnum` (required) — `"How did it turn out?"`
  - `note: String?` (optional) — `"Optional note about what happened."`
  - `nextRevisitDate: Date?` (optional) — `"Optional date to revisit this decision again."`
- **Validation**:
  - Refuse if `DecisionStore` is blocked by an unresolved restore.
  - If `decision.id` is no longer in `DecisionStore`, throw a clear localized
    error (`"That decision is no longer in Offshoots."`).
  - If `nextRevisitDate` is in the past, reject with a clear error.
- **Effect**:
  - If the decision has `actual == nil`: calls
    `store.resolveDecision(id:actual:reflection:secondaryFollowUpDate:hindsight: nil)`.
    Dialog includes prediction comparison (e.g. `"Recorded Good for \"<title>\" (you expected Neutral)."`).
  - If the decision already has `actual != nil`: calls
    `store.addRevisit(id:outcome:note:nextRevisitDate:hindsight: nil)`.
    Dialog: `"Added revisit: Good for \"<title>\"."`
  - Refreshes `WidgetSummaryWriter`, updates the entity in Spotlight.
  - Returns the updated `DecisionEntity` + dialog.

#### 3c. `ShowRevisitsDueIntent`

- **Title**: `"Show Decisions Ready to Review"`
- **Description**: `"Lists your Offshoots decisions that are currently ready for review or a revisit."`
- **Parameters**:
  - `category: DecisionCategoryAppEnum?` (optional, default `nil` = all categories)
- **Effect**:
  - Filters `store.decisions` using `isReadyForReview(asOf: .now)` (the same
    `DueDay` rule used in the app and widgets) and optional `category`.
  - Returns `[DecisionEntity]` + concise dialog:
    - 0 due: `"No decisions are ready to review right now."`
    - 1 due: `"1 decision is ready to review: <title>."`
    - N due: `"<N> decisions are ready to review, starting with <first title>."`

#### 3d. `OpenDecisionIntent` (`OpenIntent`) and `OpenReadyToReviewIntent`

- **`OpenDecisionIntent: OpenIntent`** (`target: DecisionEntity`,
  `openAppWhenRun = true`, `authenticationPolicy = .requiresAuthentication`):
  calls `AppRouteDispatcher.shared.send(.decision(target.id))`. Handles
  Spotlight taps and Shortcuts "Open Decision" actions.
- **`OpenReadyToReviewIntent: AppIntent`** (`openAppWhenRun = true`,
  `isDiscoverable = true`, title `"Open Ready to Review"`): calls
  `AppRouteDispatcher.shared.send(.readyToReview)`.

### 4. App Shortcuts (`OffshootsShortcuts: AppShortcutsProvider`)

```swift
struct OffshootsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogDecisionIntent(),
            phrases: [
                "Log a decision in \(.applicationName)",
                "Track a decision in \(.applicationName)"
            ],
            shortTitle: "Log Decision",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: RecordOutcomeIntent(),
            phrases: [
                "Record an outcome in \(.applicationName)",
                "Review a decision in \(.applicationName)"
            ],
            shortTitle: "Record Outcome",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: ShowRevisitsDueIntent(),
            phrases: [
                "Show decisions ready to review in \(.applicationName)",
                "What decisions are ready to review in \(.applicationName)"
            ],
            shortTitle: "Ready to Review",
            systemImageName: "bell.badge"
        )
    }
}
```

### 5. Donations and background widget refresh

- **Donations**:
  - After saving a new decision in `LogDecisionView`, donate `LogDecisionIntent`
    (with category/stakes, omitting private note text from the donated intent).
  - After saving in `MarkOutcomeView` or `RevisitView`, donate
    `RecordOutcomeIntent` (omitting note text).
- **Widget refresh on background intent mutations**:
  - `ShortcutsService` (registered in `AppDependencyManager`) calls
    `widgetSummary.update(decisions: store.decisions, blocked: isBlocked)`
    directly after `createDecision`, `resolveDecision`, and `addRevisit`, so
    widgets refresh even if the SwiftUI `WindowGroup` was never mounted.

### 6. Privacy and Siri AI readiness

- `authenticationPolicy = .requiresAuthentication` on every read/write/open
  intent ensures a locked phone prompts Face ID / passcode before exposing or
  changing decisions.
- Notes, reflection text, revisit notes, and Hindsight answers never enter
  `DecisionEntity`, Spotlight, donated intents, or spoken dialogs.
- When Apple's Siri AI preview (`@Property(authenticationPolicy:)` / Spring
  2027 SDKs) ships, `DecisionEntity` already has clean typed properties and full
  descriptions ready for per-property authentication annotations with no schema
  rework.
- `OpenLogDecisionIntent` (`isDiscoverable = false`, Stop 3) stays invisible in
  Shortcuts, so `"Log a Decision"` appears exactly once — as the real
  parameterized `LogDecisionIntent`.

## Testing

### Unit tests (`OffshootsTests`)

- `LogDecisionIntent` / `ShortcutsService`:
  - Creates a decision with defaults (category `.other`, stakes `.medium`,
    tomorrow review date) and with explicit values; rejects blank title and past
    review date; refuses when `blocked == true`.
  - Triggers widget summary write on creation.
- `RecordOutcomeIntent` / `ShortcutsService`:
  - Marks first outcome when `actual == nil`, adds revisit when `actual != nil`,
    leaves `hindsight` nil, rejects missing decision ID and past revisit date,
    refuses when `blocked == true`.
- `ShowRevisitsDueIntent`:
  - Returns exact due decisions matching `DueDay`, respects optional category
    filter, and formats 0 / 1 / N dialogs.
- `DecisionEntity` & `DecisionEntityQuery`:
  - Maps all allowed properties and never exposes notes, reflection, or
    Hindsight answers; `suggestedEntities()` orders due decisions first;
    `entities(matching:)` matches title and category.
- `OpenDecisionIntent` & `OpenReadyToReviewIntent`:
  - Route through `AppRouteDispatcher` to `.decision(id)` and `.readyToReview`.

### Simulator checks

- Build Debug and Release (`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`),
  run full unit test suite, and verify `scripts/archive-upload.sh --archive-only`.
- Open the Shortcuts app on the simulator and verify:
  - Offshoots appears with the 3 App Shortcuts and discoverable actions (and
    only ONE `"Log a Decision"` action).
  - Running `"Log a Decision"` in Shortcuts saves the decision, shows it in the
    app, and updates the Home Screen / Lock Screen widgets.
  - Running `"Record Outcome"` updates a pending decision and adds a revisit on
    a resolved one.
  - Running `"Show Decisions Ready to Review"` returns the due decisions.
- Spotlight search on the simulator finds a decision by title and tapping it
  opens `DecisionDetailView` (via `AppRoute.decision(id)`).

### Device checks on the iPhone 17 (stable iOS)

- Voice Siri phrases ("Log a decision in Offshoots", "Show decisions ready to
  review in Offshoots", "Record an outcome in Offshoots").
- Locked-phone test: invoking `"Show decisions ready to review in Offshoots"`
  while locked requires Face ID / passcode before reading decision titles.
- Spotlight search on-device: confirms titles appear, notes/Hindsight answers
  do **not** match Spotlight queries, and tapping opens the exact decision.
- Confirm Control Center `"Log a Decision"` button still opens the Log tab
  cleanly alongside the new Shortcuts actions.

## Signing and release

- No new entitlements, App Groups, or bundle IDs needed.
- `Offshoots` and `OffshootsWidgets` versions stay matched (`scripts/archive-upload.sh`
  already enforces this).

## Left to the builder

- File breakdown inside `Offshoots/Shortcuts/` (e.g., one file per intent vs
  grouped by entity / intents / service).
- Exact Spotlight re-index throttle or startup sync trigger (e.g., once per
  launch in `.task` after `DecisionStore` loads).
- Whether `DecisionOutcomeAppEnum` / `DecisionCategoryAppEnum` /
  `DecisionStakesAppEnum` are separate wrapper enums or direct `AppEnum`
  conformances on the existing model enums (separate wrappers keep `Decision.swift`
  free of `import AppIntents`, which is cleaner).
