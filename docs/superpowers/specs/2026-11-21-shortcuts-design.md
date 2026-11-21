# Shortcuts and Siri Starter Set — Design

Date: 2026-11-21. Status: approved by Geoff 2026-11-21.

Revised 2026-11-21 against Apple's current App Intents guidance (the
`app-intents-specialist` and `app-intents-whats-new-27` references, iOS 26 and
iOS 27 SDKs). Checked on the Mac mini (hostname `Mac`), Xcode 27.2 (27B52),
iOS 27.2 simulator SDK. See "Checked against the SDK" at the end.

## Intent

Give Offshoots its first Shortcuts and Siri actions — logging a decision,
recording an outcome or revisit, and checking which decisions are ready to
review — along with Spotlight search for decisions and in-app intent donations.

How each surface reaches the user today:

- **Siri (voice)** reaches these intents through the App Shortcuts phrases in
  §4. That is the only Siri path for intents that adopt no schema.
- **Apple Intelligence tool use** goes through the App Intent schema domains
  only. No domain that reaches Apple Intelligence or Siri fits a decision
  journal (see "Schema domains" below). This set adopts no schema.
- **Shortcuts app** shows every discoverable intent, with the parameter
  summaries in §3.
- **Spotlight** finds decisions through `IndexedEntity` (§2).

Every intent, entity, and parameter still carries clear titles, descriptions,
and parameter summaries. Personal journal notes and paid Hindsight answers stay
private and out of Siri, Spotlight, and donations.

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
- **Onscreen entity**: `DecisionDetailView` sets
  `appEntityIdentifier = EntityIdentifier(for: DecisionEntity)` on its
  `NSUserActivity` (iOS 18.2 API, no gate at 18.6). This is the current hook
  for "this decision" requests. Its effect on Siri for an entity with no schema
  is not verified; it needs a device check.
- **App Shortcuts (`OffshootsShortcuts`)**: ready-to-use Siri phrases that work
  immediately after install without manual setup in Shortcuts.
- **Intent donations**: donate `LogDecisionIntent` and `RecordOutcomeIntent`
  when the user logs a decision or marks an outcome/revisit in the app (§5).
- **Zero rework to Stop 1 or Stop 3**: `LogDecisionControl`'s internal
  `OpenLogDecisionIntent` (`isDiscoverable = false`) and all Home Screen / Lock
  Screen widgets stay untouched.

## Non-goals

- Capturing, reading, or indexing **Hindsight answers** via Siri, Shortcuts, or
  Spotlight (DECISIONS 2026-10-28: Hindsight stays in-app and model-free).
- Exposing decision notes, reflection prose, or revisit notes in `DecisionEntity`
  properties, Spotlight attributes, donations, or spoken dialogs.
- Deleting decisions, importing/exporting backups, or changing Settings via
  Shortcuts.
- Any AI / Foundation Models integration (dropped 2026-11-21).
- Adopting an App Intent schema (see "Schema domains").
- Changing `decisions.json` or `widget-summary.json` file formats.

## Anti-goals

- Personal decision details or journal notes leaking onto a locked phone via
  Siri, Spotlight, or Siri Suggestions.
- Duplicate `"Log a Decision"` actions in Shortcuts (already prevented by
  `OpenLogDecisionIntent.isDiscoverable = false`).
- Writing to `decisions.json` while a failed restore needs recovery
  (`startupError != nil || store.recoveryError != nil`).
- Separate navigation state for intents — every open action must go through
  `AppRoute` / `AppRouteDispatcher`.

## Constraints

- **iOS 18.6 minimum.** Most of this set is iOS 18 baseline API. Two pieces
  are newer and need gates:

  | API | Floor | Use here | Gate |
  | --- | --- | --- | --- |
  | `AppIntent`, `AppEntity`, `AppEnum`, `EntityStringQuery`, `AppShortcutsProvider`, `AppDependencyManager`, `IntentDonationManager`, `IntentAuthenticationPolicy` | iOS 16–17 | Everything in §1–§5 | None |
  | `IndexedEntity`, `CSSearchableIndex.indexAppEntities` / `deleteAppEntities` | iOS 18.0 | Spotlight (§2) | None |
  | `NSUserActivity.appEntityIdentifier`, `EntityIdentifier(for:)` | iOS 18.2 | Onscreen entity | None |
  | `@Property(title:indexingKey:)` | iOS 18.4 | `title` into Spotlight's title key | None |
  | `supportedModes` / `IntentModes` | iOS 26.0 | Open intents (§3d) | `@available(iOS 26.0, *)` on the property |
  | `IndexedEntityQuery` (`reindexEntities` / `reindexAllEntities`) | iOS 27.0 | System-driven Spotlight reindex (§2) | `@available(iOS 27.0, *)` extension |

  `openAppWhenRun` is deprecated in iOS 26. At an 18.6 deployment target it
  stays, and the open intents add a gated `supportedModes` beside it (§3d).
- **App target only for the new intents.** All Shortcuts intents,
  `DecisionEntity`, Spotlight indexing, and `OffshootsShortcuts` live in the
  `Offshoots` app target (`Offshoots/Shortcuts/`), where `DecisionStore` and
  `Decision` live. `OffshootsWidgets` keeps only `OpenLogDecisionIntent` from
  `Shared/`. There is no App Intents extension, so the intents run in the app
  process and `App.init()` runs first on every launch, including a cold launch
  from Siri.
- **Isolation.** The app target defaults to main-actor isolation with
  approachable concurrency.
  - Do **not** write `nonisolated` on intent, entity, query, or enum types that
    have stored `@Parameter`, `@Property`, or `@Dependency` members. The
    compiler rejects it ("'nonisolated' cannot be applied to mutable stored
    properties"). Without the keyword, the same types typecheck clean (checked,
    see the end). `OpenLogDecisionIntent` can keep its `nonisolated` because it
    has no stored properties.
  - `perform()` is not main-actor by default. Mark it `@MainActor` when it
    touches `DecisionStore`. Query methods hop with `await MainActor.run { … }`
    to read the store.
  - `DecisionStore` is an `@Observable` class, main-actor by default, so it is
    `Sendable` and can be a `@Dependency`. `ShortcutsService` follows the same
    rule.
- **Widget sync stays automatic.** Intents mutate `DecisionStore` and refresh
  `WidgetSummaryWriter` directly (§5), so Home Screen and Lock Screen widgets
  stay in sync even when no scene is mounted.
- **Same scheme and release rules.** No changes to `Offshoots.xcscheme`'s Run
  action, launch arguments, `Reflection.storekit`, or `selectedTab` default.

## Approaches

### How intents access `DecisionStore` and refresh widgets

A background intent runs in the app process, possibly when no SwiftUI scene
(`WindowGroup`) is mounted.

- **Option A — Read/write `decisions.json` directly inside each intent.**
  Rejected: duplicates `DecisionStore`'s serialization, bypasses reminder
  scheduling (`ReminderManager`), risks racing with an open app's in-memory
  store, and skips `WidgetSummaryWriter`.
- **Option B — Register a `ShortcutsService` via `AppDependencyManager` in `OffshootsApp.init()` (picked).**
  `OffshootsApp.init()` runs once per process launch, performs
  `JournalDataCoordinator.recover`, creates the single `DecisionStore`, and
  registers `AppRouteDispatcher`.
  - **Code change needed:** `WidgetSummaryWriter` is today a `@State` property
    initializer (`OffshootsApp.swift`), not built in `init()`. Move its
    construction into `init()` (`_widgetSummary = State(initialValue: writer)`)
    so the UI and the service hold the same instance.
  - `init()` then builds a `ShortcutsService` that holds the store, the writer,
    and the recovery-blocked flag, and calls
    `AppDependencyManager.shared.add(dependency: service)`. Register in
    `init()` only. A registration from a view never runs on a cold Siri launch,
    and an unregistered `@Dependency` is a `fatalError`.
  - Put `@Dependency` on intents and `DecisionEntityQuery` only. It does not
    resolve on an `AppEntity` or `AppEnum`.
  - Result: background intents and the UI share one store, recovery blocking is
    the same everywhere, reminders go through `DecisionStore`, and the service
    refreshes widgets after each mutation.

### Schema domains

Apple's schema catalog splits by surface. The domains that reach Apple
Intelligence and Siri are audio, calendar, camera, clock, files, mail, maps,
messages, notes, phone, photos, reminders, and system. None matches "log a
decision and predict its outcome", and a forced fit degrades Siri's behavior.
`journal` exists (`CreateJournalEntryIntent`, `SearchJournalEntriesIntent`, and
others) but reaches the Shortcuts app only, not Apple Intelligence or Siri.
Its required fields are not visible in the SDK interface (a build tool checks
them), so whether it would push note text into the system is not verified.
Decision: adopt no schema in v1. Revisit if Apple adds a domain that fits.

## Design

### 1. Shared AppEnums (`Offshoots/Shortcuts/DecisionAppEnums.swift`)

`AppEnum` raw values are a persisted contract. Saved shortcuts and donations
store them as strings. Use the model's existing raw values, never renumber or
rename, and only append. Every case needs a `caseDisplayRepresentations` entry;
a missing entry is a runtime `fatalError`.

- **`DecisionOutcomeAppEnum`** (labels match `DecisionOutcome.shortLabel`):

  | Case | Raw value | Display |
  | --- | --- | --- |
  | `.veryBad` | `"very bad"` | Very Bad |
  | `.bad` | `"bad"` | Bad |
  | `.neutral` | `"neutral"` | Neutral |
  | `.good` | `"good"` | Good |
  | `.veryGood` | `"very good"` | Great |

- **`DecisionCategoryAppEnum`**: `work`, `money`, `health`, `relationships`,
  `home`, `other` (raw values as in `DecisionCategory`), displayed Work, Money,
  Health, Relationships, Home, Other.
- **`DecisionStakesAppEnum`**: `low`, `medium`, `high` (raw values as in
  `DecisionStakes`), displayed Low, Medium, High.

Use separate wrapper enums so `Decision.swift` stays free of `import AppIntents`.

### 2. `DecisionEntity` and Spotlight indexing (`Offshoots/Shortcuts/DecisionEntity.swift`)

```swift
struct DecisionEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("Decision"),
        numericFormat: "\(placeholder: .int) decisions"
    )
    static let defaultQuery = DecisionEntityQuery()

    let id: UUID   // Decision.id — stable across launches; a public contract
    @Property(title: "Title", indexingKey: \.title) var title: String
    @Property(title: "Category") var category: DecisionCategoryAppEnum
    @Property(title: "Stakes") var stakes: DecisionStakesAppEnum
    @Property(title: "Expected Outcome") var expected: DecisionOutcomeAppEnum
    @Property(title: "Current Outcome") var currentOutcome: DecisionOutcomeAppEnum?
    @Property(title: "Next Review Date") var nextReviewDate: Date?
    @Property(title: "Ready to Review") var isReadyForReview: Bool
}
```

- **Display representation**: `title` as title, subtitle
  `"<Category> · <currentOutcome, or Expected <expected>>"`. Do not put
  "Ready to review" in the display representation. Spotlight stores the
  display text at index time, and a due-state subtitle goes stale the moment
  the day turns. `isReadyForReview` stays a property for Shortcuts filtering.
- **Privacy boundary**: `notes`, `reflection`, revisit notes, and `hindsight`
  answers are **not** properties on `DecisionEntity` and are **never** written
  to Spotlight (`attributeSet`).
- **Query (`DecisionEntityQuery: EntityStringQuery`)**, with
  `@Dependency var service: ShortcutsService`:
  - `entities(for identifiers: [UUID])`: one batched lookup in `DecisionStore`.
  - `entities(matching string: String)`: case-insensitive substring match on
    `title` and category display name. The framework does not filter for us.
  - `suggestedEntities()`: decisions ready to review first (soonest first),
    then the most recent pending decisions, capped at 10.
- **Spotlight indexing (`DecisionSpotlightIndexer`)**:
  - Uses `CSSearchableIndex.default().indexAppEntities(...)` on create, update,
    resolve, revisit, and import; `deleteAppEntities(identifiedBy:ofType:)` on
    delete; `deleteAllAppEntities(ofType:)` on Delete All. Hook these into
    `DecisionStore`'s mutation paths so in-app edits and intents both index.
  - **iOS 27+**: a gated `extension DecisionEntityQuery: IndexedEntityQuery`
    implements `reindexEntities(for:indexDescription:)` and
    `reindexAllEntities(indexDescription:)`, so the system can ask for a
    reindex. Skip both when recovery blocks the store.
  - **iOS 18.6–26**: a startup sync on launch (when not blocked by recovery) so
    existing journals become searchable after updating to this version. Run it
    once per launch after `DecisionStore` loads.
  - Opening a Spotlight hit invokes `OpenDecisionIntent` (`OpenIntent`), which
    calls `AppRouteDispatcher.shared.send(.decision(target.id))`.

### 3. Discoverable App Intents (`Offshoots/Shortcuts/`)

Rules for every intent:

- `static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication`
  so Siri and Shortcuts require an unlocked phone before reading or modifying
  decisions.
- A literal `IntentDescription(...)` with a `categoryName`.
- An explicit `parameterSummary`. Only the parameters it names appear in the
  Shortcuts editor, in summary order.
- **`perform()` can run more than once.** `needsValueError` and
  `restartPerform` re-enter it from the top with no rollback. Do all
  validation and every value request first, and mutate the store last.
- Errors: one `ShortcutsError` enum that conforms to
  `CustomLocalizedStringResourceConvertible`. Other error types show a
  generic message.
- Dialogs and errors are literal `LocalizedStringResource` templates with
  interpolation, so the string catalog extracts them. No runtime `String`.
- Background intents declare no `supportedModes`. The default is background,
  which is what they need.

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
- **Parameter summary**: `Summary("Log \(\.$title) expecting \(\.$expected)") { \.$category; \.$stakes; \.$reviewDate; \.$notes }`
- **Order inside `perform()`**:
  1. Refuse with `ShortcutsError.blocked` if `DecisionStore` is blocked by an
     unresolved restore.
  2. If `title` is blank after trimming, `throw $title.needsValueError(...)`
     so Siri asks again, rather than failing.
  3. Reject a `reviewDate` before `Calendar.current.startOfDay(for: .now)`
     (DECISIONS 2026-09-26).
  4. Only then call `store.createDecision(...)` (saves journal, schedules
     reminder if enabled), refresh `WidgetSummaryWriter`, and index the entity.
- **Result**: `some ReturnsValue<DecisionEntity> & ProvidesDialog` —
  `"Logged \"<title>\" in <Category>. Review set for <formatted date>."`

#### 3b. `RecordOutcomeIntent`

- **Title**: `"Record Outcome"`
- **Description**: `"Records how a decision actually turned out, or adds a new revisit rating to an already-marked decision."`
- **Parameters**:
  - `decision: DecisionEntity` (required) — `"Which decision?"`
  - `outcome: DecisionOutcomeAppEnum` (required) — `"How did it turn out?"`
  - `note: String?` (optional) — `"Optional note about what happened."`
  - `nextRevisitDate: Date?` (optional) — `"Optional date to revisit this decision again."`
- **Parameter summary**: `Summary("Record \(\.$outcome) for \(\.$decision)") { \.$note; \.$nextRevisitDate }`
- **Order inside `perform()`**:
  1. Refuse if `DecisionStore` is blocked by an unresolved restore.
  2. If `decision.id` is no longer in `DecisionStore`, throw
     `ShortcutsError.decisionMissing` (`"That decision is no longer in Offshoots."`).
  3. Reject a past `nextRevisitDate`.
  4. Then mutate:
     - `actual == nil`: `store.resolveDecision(id:actual:reflection:secondaryFollowUpDate:hindsight: nil)`.
       Dialog: `"Recorded Good for \"<title>\" (you expected Neutral)."`
     - `actual != nil`: `store.addRevisit(id:outcome:note:nextRevisitDate:hindsight: nil)`.
       Dialog: `"Added revisit: Good for \"<title>\"."`
  5. Refresh `WidgetSummaryWriter` and reindex the entity.
- **Result**: `some ReturnsValue<DecisionEntity> & ProvidesDialog`.

#### 3c. `ShowRevisitsDueIntent`

- **Title**: `"Show Decisions Ready to Review"`
- **Description**: `"Lists your Offshoots decisions that are currently ready for review or a revisit."`
- **Parameters**:
  - `category: DecisionCategoryAppEnum?` (optional, default `nil` = all categories)
- **Parameter summary**: `Summary("Show decisions ready to review") { \.$category }`
- **Effect**:
  - Filters `store.decisions` using `isReadyForReview(asOf: .now)` (the same
    `DueDay` rule used in the app and widgets) and optional `category`.
  - Read-only, so a re-run is harmless.
  - Returns `some ReturnsValue<[DecisionEntity]> & ProvidesDialog`:
    - 0 due: `"No decisions are ready to review right now."`
    - 1 due: `"1 decision is ready to review: <title>."`
    - N due: `"<N> decisions are ready to review, starting with <first title>."`

#### 3d. `OpenDecisionIntent` (`OpenIntent`) and `OpenReadyToReviewIntent`

Both open the app. Each declares both forms, which typecheck together at an
18.6 target (checked):

```swift
static let openAppWhenRun: Bool = true          // iOS 18.6–25
@available(iOS 26.0, *)
static var supportedModes: IntentModes { .foreground(.immediate) }   // iOS 26+
```

- **`OpenDecisionIntent: OpenIntent`** (`target: DecisionEntity`,
  `authenticationPolicy = .requiresAuthentication`): `@MainActor perform()`
  calls `AppRouteDispatcher.shared.send(.decision(target.id))`. Handles
  Spotlight taps and the Shortcuts "Open Decision" action.
- **`OpenReadyToReviewIntent: AppIntent`** (`isDiscoverable = true`, title
  `"Open Ready to Review"`): calls `AppRouteDispatcher.shared.send(.readyToReview)`.

### 4. App Shortcuts (`OffshootsShortcuts: AppShortcutsProvider`)

Every phrase includes `\(.applicationName)`; the runtime index drops a phrase
without it. Every shortcut has `shortTitle` and a literal `systemImageName`
(the initializer without them is deprecated). Once shipped, these phrases are a
contract: add new ones, do not rename or remove.

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

- **Donations** (in-app actions are not donated automatically):
  - Donate from the views only, after the save succeeds. Never donate from
    `perform()`; the system already donates the intents it runs.
  - After `LogDecisionView` saves: donate `LogDecisionIntent` with only
    `category` and `stakes` set.
  - After `MarkOutcomeView` or `RevisitView` saves: donate
    `RecordOutcomeIntent` with only `outcome` set.
  - Never put the title, notes, or a `DecisionEntity` in a donation. This
    keeps titles out of Siri Suggestions on a locked phone, and leaves no stale
    donation to clean up when a decision is deleted.
  - Use `try? await IntentDonationManager.shared.donate(intent:)`. A donation
    with unset required parameters typechecks; whether the system then
    suggests it usefully is not verified and needs a device check.
- **Widget refresh on background intent mutations**:
  - `ShortcutsService` calls
    `widgetSummary.update(decisions: store.decisions, blocked: isBlocked)`
    directly after `createDecision`, `resolveDecision`, and `addRevisit`, so
    widgets refresh even if the SwiftUI `WindowGroup` was never mounted.

### 6. Privacy

- `authenticationPolicy = .requiresAuthentication` on every read, write, and
  open intent, so a locked phone asks for Face ID or the passcode before it
  exposes or changes decisions.
- Notes, reflection text, revisit notes, and Hindsight answers never enter
  `DecisionEntity`, Spotlight, donations, or spoken dialogs.
- `OpenLogDecisionIntent` (`isDiscoverable = false`, Stop 3) stays invisible in
  Shortcuts, so `"Log a Decision"` appears exactly once — as the real
  parameterized `LogDecisionIntent`.

### 7. Checked, not adopted

Current APIs reviewed and left out of v1:

- **`SnippetIntent` / interactive snippets** (iOS 26): the spoken dialog is
  enough for a list of due titles.
- **`requestChoice`** (iOS 26): no step needs a mid-run choice.
- **`UndoableIntent`** (iOS 26): no destructive intent in the set.
- **`CancellableIntent`, `LongRunningIntent`** (iOS 26.4, 27): every intent
  finishes in well under the 30-second limit.
- **`RelevantEntities`** (iOS 27): the shipping contexts are audio and workout
  only.
- **`SyncableEntity` / `EntityOwnership`** (iOS 27): no cross-device sync or
  sharing.
- **`EntityCollection`** (iOS 27): journals are small; `[DecisionEntity]` is
  fine.
- **Visual Intelligence (`IntentValueQuery`)** (iOS 26): no camera or
  on-screen search use.
- **`allowedExecutionTargets`** (iOS 27): no extension, so the default runs in
  the app.
- **`EntityPropertyQuery`**: "Find decisions where…" can come later if asked.

Later, not this set: `OpenLogDecisionIntent` still uses only `openAppWhenRun`.
Add the gated `supportedModes` there when Stop 3 code is next touched.

## Testing

### Unit tests (`OffshootsTests`, Swift Testing)

Main coverage runs in-process against `ShortcutsService` and the query:

- `LogDecisionIntent` / `ShortcutsService`:
  - Creates a decision with defaults (category `.other`, stakes `.medium`,
    tomorrow review date) and with explicit values; rejects blank title and past
    review date; refuses when `blocked == true`.
  - Validation failures leave the store unchanged (no partial write before a
    value request).
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
- AppEnums: raw values equal the model raw values; every case has a display
  representation.
- `OpenDecisionIntent` & `OpenReadyToReviewIntent`:
  - Route through `AppRouteDispatcher` to `.decision(id)` and `.readyToReview`.

### Optional: `AppIntentsTesting` smoke test

`AppIntentsTesting` (iOS 27.0, XCTest only) runs intents out of process against
the installed app, the same way Siri does, using the app's real data. If the
builder adds it, keep it to one XCTest class that logs a decision and reads it
back through `ShowRevisitsDueIntent`, and run it only on a seeded simulator
this run owns. Not required for v1.

### Simulator checks

- Build Debug and Release (`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`).
  During work, run only the focused tests. The full suite is the merge gate.
  Verify `scripts/archive-upload.sh --archive-only` before merge.
- Open the Shortcuts app on the simulator and verify:
  - Offshoots appears with the 3 App Shortcuts and discoverable actions (and
    only ONE `"Log a Decision"` action).
  - The parameter summaries read as written in §3.
  - Running `"Log a Decision"` in Shortcuts saves the decision, shows it in the
    app, and updates the Home Screen / Lock Screen widgets.
  - Running `"Record Outcome"` updates a pending decision and adds a revisit on
    a resolved one.
  - Running `"Show Decisions Ready to Review"` returns the due decisions.
- Spotlight search on the simulator finds a decision by title and tapping it
  opens `DecisionDetailView` (via `AppRoute.decision(id)`).
- Run the Spotlight and Shortcuts checks on an iOS 27 simulator. Neither Mac
  has a runtime older than iOS 27.0 (2026-11-10), so the iOS 18.6–26 paths
  (startup reindex, `openAppWhenRun` alone) are not checked on a simulator.
  Say so in the report.

### Device checks on the iPhone 17 (stable iOS)

- Voice Siri phrases ("Log a decision in Offshoots", "Show decisions ready to
  review in Offshoots", "Record an outcome in Offshoots").
- Cold launch: with Offshoots force-quit, run each phrase. No crash (proves
  the `@Dependency` registration runs in `init()`).
- Locked-phone test: invoking `"Show decisions ready to review in Offshoots"`
  while locked requires Face ID / passcode before reading decision titles.
- Spotlight search on-device: confirms titles appear, notes/Hindsight answers
  do **not** match Spotlight queries, and tapping opens the exact decision.
- Donations: after logging a few decisions in the app, check whether Siri
  Suggestions offer "Log a Decision" and that no decision title appears in the
  suggestion.
- Onscreen entity: with a decision open, ask Siri about "this decision" and
  record what happens. The result is information, not a pass/fail gate.
- Confirm Control Center `"Log a Decision"` button still opens the Log tab
  cleanly alongside the new Shortcuts actions.

## Signing and release

- No new entitlements, App Groups, or bundle IDs needed.
- `Offshoots` and `OffshootsWidgets` versions stay matched (`scripts/archive-upload.sh`
  already enforces this).

## Left to the builder

- File breakdown inside `Offshoots/Shortcuts/` (e.g., one file per intent vs
  grouped by entity / intents / service).
- How `DecisionStore`'s mutation paths call `DecisionSpotlightIndexer`
  (direct call vs a small hook closure).

## Checked against the SDK

Mac mini (hostname `Mac`), Xcode 27.2 (27B52), iOS 27.2 simulator SDK,
2026-11-21. A probe file was typechecked with `swiftc -typecheck`,
`-swift-version 6`, `-default-isolation MainActor`, the approachable
concurrency features (`InferIsolatedConformances`,
`NonisolatedNonsendingByDefault`) plus `MemberImportVisibility`, at
`-target arm64-apple-ios18.6-simulator`. Results:

- `openAppWhenRun` plus `@available(iOS 26.0, *) supportedModes` in one
  `OpenIntent`: compiles.
- `@available(iOS 27.0, *) extension <Query>: IndexedEntityQuery`: compiles.
- `@Property(title:indexingKey: \.title)` with no gate: compiles.
- `IntentDonationManager.shared.donate(intent:)` with unset parameters:
  compiles.
- `NSUserActivity.appEntityIdentifier = EntityIdentifier(for:)` with no gate:
  compiles.
- `nonisolated` on types with stored `@Parameter` / `@Property` /
  `@Dependency`: fails. The same file without `nonisolated` compiles with no
  diagnostics.

Not verified here: runtime behavior of any of the above, the `journal`
schema's required fields, and everything listed under device checks.
