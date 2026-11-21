# Shortcuts and Siri Starter Set Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three discoverable App Intents, two open intents, a `DecisionEntity` with Spotlight indexing, App Shortcuts phrases, and in-app donations to Offshoots.

**Architecture:** A main-actor `ShortcutsService` owns all intent logic (validation, store mutation, widget refresh, dialog text) and is registered with `AppDependencyManager` in `OffshootsApp.init()`. Intents and the entity query are thin wrappers that call it. `DecisionStore` reports mutations through one hook that the Spotlight indexer uses.

**Tech Stack:** SwiftUI, App Intents, Core Spotlight, Swift Testing. Xcode 27.2, iOS 27.2 SDK, iOS 18.6 deployment target.

**Spec:** `docs/superpowers/specs/2026-11-21-shortcuts-design.md` (approved 2026-11-21). Read it before each task.

## Global Constraints

- Work on branch `dev/shortcuts`, created from `main`. Geoff pushes.
- iOS 18.6 minimum. Gate `supportedModes` with `@available(iOS 26.0, *)` and `IndexedEntityQuery` with `@available(iOS 27.0, *)`. Everything else in this plan is ungated.
- New files go in `Offshoots/Shortcuts/` (app target only). The project uses synchronized folders; a new file needs no `project.pbxproj` change. Tests go in `OffshootsTests/`.
- Do not write `nonisolated` on a type that has stored `@Parameter`, `@Property`, or `@Dependency` members. Mark `perform()` `@MainActor` when it touches the store.
- `@Dependency` goes on intents and `DecisionEntityQuery` only, never on `DecisionEntity` or an `AppEnum`.
- Notes, reflection, revisit notes, and Hindsight answers never enter `DecisionEntity`, Spotlight, donations, or dialogs. Intents always pass `hindsight: nil`.
- Every intent: `authenticationPolicy = .requiresAuthentication`, literal `IntentDescription`, explicit `parameterSummary`.
- `perform()` validates first and mutates last.
- `AppEnum` raw values equal the model raw values. Every case has a display representation.
- Dialog and error text are literal `LocalizedStringResource` templates. No runtime `String` for user-facing text.
- Do not touch `OpenLogDecisionIntent`, the widgets, or `Offshoots.xcscheme`.
- **Review date rule (follows the app):** the earliest review date for a new decision is the start of tomorrow (`LogDecisionView.earliestReviewDate`, DECISIONS 2026-09-26). The earliest next-revisit date is the start of today (`RevisitView` allows today). The spec text that says "before start of today" for a new decision is wrong; the doc commit with this plan corrects it.
- Tests: run only the focused suite during a task (`-only-testing:OffshootsTests/<Suite>`), `-parallel-testing-enabled NO -collect-test-diagnostics never`, on a simulator this run owns (CLAUDE.md "Build and test"). Full suite only in Task 6.

Test command used below (set once per session per CLAUDE.md):

```
export RUN_ID="offshoots-$(date +%Y%m%d-%H%M%S)"
V=.claude/skills/verify-offshoots/verify.sh
$V up
SIMULATOR_UDID="$($V sim)"
T() { DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination "id=$SIMULATOR_UDID" -parallel-testing-enabled NO -collect-test-diagnostics never test "$@"; }
```

## Review Focus

1. **Recovery-blocked store.** A Siri run while a restore needs recovery must write nothing, change no widget file, and index nothing. Tests: Task 1 `blockedStoreRefusesEveryWrite`, Task 3 `blockedStoreSkipsIndexing`.
2. **Whitespace-only and padded titles.** `"   "` must be refused before any write; `"  Take the job "` is saved trimmed. Test: Task 1 `trimsTitleAndRefusesBlank`.
3. **Decision deleted between pick and run.** A saved shortcut that still holds a deleted decision's ID must fail with the "no longer in Offshoots" message and write nothing. Test: Task 1 `missingDecisionThrowsAndWritesNothing`.
4. **Today as a review date.** Siri passes "today" for a new decision: refused (same-day review is ready at once). Today as a next-revisit date: allowed. Tests: Task 1 `reviewDateMustBeTomorrowOrLater`, `revisitDateTodayIsAllowed`.
5. **Category filter with no matches, and due-state at day change.** "Show ready to review" for an empty category says the 0 dialog; a decision due today is due, one due tomorrow is not. Test: Task 1 `readyForReviewFiltersByCategoryAndDueDay`.

---

### Task 1: `ShortcutsService` and `ShortcutsError`

**Files:**
- Create: `Offshoots/Shortcuts/ShortcutsService.swift`
- Create: `Offshoots/Shortcuts/ShortcutsError.swift`
- Modify: `Offshoots/DecisionStore.swift` — `createDecision` returns the new `Decision` (`@discardableResult`); `addRevisit` returns `Bool` (`@discardableResult`, false when the decision is gone or has no outcome), matching `resolveDecision`.
- Test: `OffshootsTests/ShortcutsServiceTests.swift`

**Interfaces:**
- Produces:
  ```swift
  @MainActor final class ShortcutsService {
      init(store: DecisionStore, widgetSummary: WidgetSummaryWriter, now: @escaping () -> Date = { .now })
      var isBlocked: Bool                       // store.recoveryError != nil
      var decisions: [Decision]                 // store.decisions
      func logDecision(title: String, expected: DecisionOutcome, category: DecisionCategory,
                       stakes: DecisionStakes, reviewDate: Date?, notes: String?) throws -> Decision
      enum RecordResult { case firstOutcome(Decision), revisit(Decision) }
      func recordOutcome(decisionID: UUID, outcome: DecisionOutcome, note: String?,
                         nextRevisitDate: Date?) throws -> RecordResult
      func readyForReview(category: DecisionCategory?) -> [Decision]   // most overdue first
  }
  enum ShortcutsError: Error, Equatable, CustomLocalizedStringResourceConvertible {
      case blocked, blankTitle, reviewDateTooEarly, revisitDateInPast, decisionMissing
  }
  ```
- `DecisionStore.createDecision(...) -> Decision`, `DecisionStore.addRevisit(...) -> Bool`.

Pinned values:
- `logDecision`: trims `title` (whitespaces and newlines); blank → `.blankTitle`. `reviewDate == nil` → `ReviewDatePreset.tomorrow.date(from: now())`. `reviewDate < startOfDay(tomorrow)` → `.reviewDateTooEarly`. Blank-after-trim notes → nil. Checks run in this order: blocked, blank title, review date. Then `store.createDecision`, then `widgetSummary.update(decisions:blocked:now:)`.
- `recordOutcome`: blocked → `.blocked`; ID not in store → `.decisionMissing`; `nextRevisitDate < startOfDay(now())` → `.revisitDateInPast`. `actual == nil` → `resolveDecision(id:actual:reflection: note, secondaryFollowUpDate: nextRevisitDate, hindsight: nil)`; else `addRevisit(id:outcome:note:nextRevisitDate:hindsight: nil)`. Then refresh widgets. Return the decision as stored after the write.
- `readyForReview`: `isReadyForReview(asOf: now())`, optional category filter, sorted by `nextReviewDate` ascending (same as `DecisionStore.readyForReviewDecisions`).
- Error messages (exact copy):
  - `.blocked`: "Offshoots needs attention before it can save. Open the app to finish the restore."
  - `.blankTitle`: "What decision are you making?"
  - `.reviewDateTooEarly`: "Pick a review date of tomorrow or later."
  - `.revisitDateInPast`: "Pick a revisit date of today or later."
  - `.decisionMissing`: "That decision is no longer in Offshoots."

- [ ] **Step 1: Create the branch**

Run: `git -C /Users/geoffreysilva/Developer/Offshoots switch -c dev/shortcuts`
Expected: `Switched to a new branch 'dev/shortcuts'`

- [ ] **Step 2: Write the failing tests**

`@MainActor @Suite struct ShortcutsServiceTests`, each test with a fresh temp-folder `DecisionStore(saveURL:)` (pattern: `DecisionStoreTests`), a `WidgetSummaryWriter(fileURL: tempURL) { counter += 1 }` (pattern: `WidgetSummaryWriterTests`), and `now: { Make.day(26) }`.

```swift
@Test func logsWithDefaults() throws {
    let d = try service.logDecision(title: "Take the job", expected: .good, category: .other,
                                    stakes: .medium, reviewDate: nil, notes: nil)
    #expect(store.decisions.map(\.id) == [d.id])
    #expect(d.followUpDate == ReviewDatePreset.tomorrow.date(from: Make.day(26)))
    #expect(d.category == .other && d.stakes == .medium && d.notes == nil)
    writer.waitForPendingWrites(); #expect(reloads.count == 1)
}
@Test func trimsTitleAndRefusesBlank() throws {
    #expect(throws: ShortcutsError.blankTitle) { try service.logDecision(title: "  \n", /* … */) }
    #expect(store.decisions.isEmpty)
    let d = try service.logDecision(title: "  Take the job ", /* … */ notes: "   ")
    #expect(d.title == "Take the job" && d.notes == nil)
}
@Test func reviewDateMustBeTomorrowOrLater() {
    #expect(throws: ShortcutsError.reviewDateTooEarly) { try service.logDecision(/* … */ reviewDate: Make.day(26)) }
    #expect(store.decisions.isEmpty)
    #expect(throws: Never.self) { try service.logDecision(/* … */ reviewDate: Make.day(27)) }
}
@Test func blockedStoreRefusesEveryWrite() {
    store.blockAfterRestoreFailure()
    #expect(throws: ShortcutsError.blocked) { try service.logDecision(/* valid */) }
    #expect(throws: ShortcutsError.blocked) { try service.recordOutcome(decisionID: UUID(), outcome: .good, note: nil, nextRevisitDate: nil) }
    writer.waitForPendingWrites(); #expect(reloads.count == 0)
}
@Test func firstOutcomeThenRevisit() throws {
    // seed one pending decision (expected .neutral) via store.add(Make.decision(expected: .neutral, followUpDate: Make.day(20)))
    guard case .firstOutcome(let first) = try service.recordOutcome(decisionID: id, outcome: .good, note: nil, nextRevisitDate: nil) else { Issue.record(); return }
    #expect(first.actual == .good && first.hindsight == nil)
    guard case .revisit(let second) = try service.recordOutcome(decisionID: id, outcome: .bad, note: "  ", nextRevisitDate: nil) else { Issue.record(); return }
    #expect(second.actual == .good)                       // first outcome unchanged
    #expect(second.revisits.map(\.outcome) == [.bad])
    #expect(second.revisits.last?.hindsight == nil)
}
@Test func missingDecisionThrowsAndWritesNothing() {
    #expect(throws: ShortcutsError.decisionMissing) { try service.recordOutcome(decisionID: UUID(), outcome: .good, note: nil, nextRevisitDate: nil) }
    writer.waitForPendingWrites(); #expect(reloads.count == 0)
}
@Test func revisitDateTodayIsAllowed() throws {
    // seed pending decision; record with nextRevisitDate: Make.day(26) succeeds; Make.day(25) throws .revisitDateInPast
}
@Test func readyForReviewFiltersByCategoryAndDueDay() {
    // seed: work due day 26, money due day 26, work due day 27, work resolved with no revisit date
    #expect(service.readyForReview(category: nil).count == 2)
    #expect(service.readyForReview(category: .work).map(\.title) == ["work due today"])
    #expect(service.readyForReview(category: .health).isEmpty)
}
@Test func errorMessagesMatchSpecCopy() {
    #expect(String(localized: ShortcutsError.decisionMissing.localizedStringResource) == "That decision is no longer in Offshoots.")
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `T -only-testing:OffshootsTests/ShortcutsServiceTests`
Expected: build fails, "cannot find 'ShortcutsService' in scope".

- [ ] **Step 4: Implement `ShortcutsError`, `ShortcutsService`, and the two `DecisionStore` return values**

Existing `DecisionStore` callers ignore the new return values (`@discardableResult`), so no view changes.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `T -only-testing:OffshootsTests/ShortcutsServiceTests -only-testing:OffshootsTests/DecisionStoreTests`
Expected: `** TEST SUCCEEDED **`, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add Offshoots/Shortcuts Offshoots/DecisionStore.swift OffshootsTests/ShortcutsServiceTests.swift
git commit -m "feat: add ShortcutsService for Siri and Shortcuts writes"
```

---

### Task 2: AppEnums, `DecisionEntity`, and `DecisionEntityQuery`

**Files:**
- Create: `Offshoots/Shortcuts/DecisionAppEnums.swift`
- Create: `Offshoots/Shortcuts/DecisionEntity.swift` (entity + query)
- Test: `OffshootsTests/DecisionEntityTests.swift`

**Interfaces:**
- Consumes: `ShortcutsService.decisions`, `ShortcutsService.readyForReview(category:)`.
- Produces:
  ```swift
  enum DecisionOutcomeAppEnum: String, AppEnum { init(_ model: DecisionOutcome); var model: DecisionOutcome }
  enum DecisionCategoryAppEnum: String, AppEnum { init(_ model: DecisionCategory); var model: DecisionCategory }
  enum DecisionStakesAppEnum: String, AppEnum { init(_ model: DecisionStakes); var model: DecisionStakes }
  struct DecisionEntity: AppEntity, IndexedEntity { init(_ decision: Decision, now: Date) }
  struct DecisionEntityQuery: EntityStringQuery {
      @Dependency var service: ShortcutsService
      static func suggestions(from decisions: [Decision], now: Date) -> [Decision]   // pure, for tests
      static func matches(_ decisions: [Decision], string: String) -> [Decision]     // pure, for tests
  }
  ```

Pinned values:
- Raw values and display names: spec §1 tables (`"very bad"` … `"very good"`; Great for `.veryGood`).
- Entity properties and `typeDisplayRepresentation`: spec §2 code block, including `@Property(title: "Title", indexingKey: \.title)`.
- Display subtitle: `"<Category> · <current outcome label>"` when marked, else `"<Category> · Expected <expected label>"`. Never "Ready to review".
- `suggestions`: ready-to-review (soonest `nextReviewDate` first), then pending not yet due by `createdAt` descending, total capped at 10, no duplicates.
- `matches`: case- and diacritic-insensitive substring on title or category display name.
- Query methods read the service with `await MainActor.run { … }`.

- [ ] **Step 1: Write the failing tests**

```swift
@Test func enumRawValuesMatchModel() {
    for o in DecisionOutcome.allCases { #expect(DecisionOutcomeAppEnum(o).rawValue == o.rawValue && DecisionOutcomeAppEnum(o).model == o) }
    for c in DecisionCategory.allCases { #expect(DecisionCategoryAppEnum(c).rawValue == c.rawValue) }
    for s in DecisionStakes.allCases { #expect(DecisionStakesAppEnum(s).rawValue == s.rawValue) }
    #expect(DecisionOutcomeAppEnum.caseDisplayRepresentations.count == DecisionOutcome.allCases.count)
    #expect(DecisionCategoryAppEnum.caseDisplayRepresentations.count == 6)
    #expect(DecisionStakesAppEnum.caseDisplayRepresentations.count == 3)
}
@Test func entityMapsFieldsAndHidesPrivateText() {
    // Decision with notes "secret note", reflection "secret reflection", hindsight set, a revisit with note "secret revisit"
    let e = DecisionEntity(decision, now: Make.day(26))
    #expect(e.id == decision.id && e.title == decision.title && e.currentOutcome == DecisionOutcomeAppEnum(.bad))
    let text = String(describing: e.displayRepresentation) + String(describing: Mirror(reflecting: e).children.map(\.value))
    #expect(!text.contains("secret"))
}
@Test func subtitleNeverSaysReadyToReview() { /* due decision: subtitle == "Work · Expected Good" */ }
@Test func suggestionsPutDueFirstAndCapAtTen() { /* 3 due + 12 pending → 10 results, first 3 are the due ones soonest first */ }
@Test func stringMatchCoversTitleAndCategory() { /* "JOB" matches "Take the job"; "money" matches a money decision */ }
```

- [ ] **Step 2: Run to verify failure**

Run: `T -only-testing:OffshootsTests/DecisionEntityTests`
Expected: build fails, "cannot find 'DecisionEntity' in scope".

- [ ] **Step 3: Implement the enums, entity, and query**

`entities(for:)` filters `service.decisions` by the ID set in one pass. `suggestedEntities()` and `entities(matching:)` call the static helpers.

- [ ] **Step 4: Run to verify pass**

Run: `T -only-testing:OffshootsTests/DecisionEntityTests`
Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add Offshoots/Shortcuts OffshootsTests/DecisionEntityTests.swift
git commit -m "feat: add DecisionEntity, query, and App Intents enums"
```

---

### Task 3: App wiring and Spotlight indexing

**Files:**
- Create: `Offshoots/Shortcuts/DecisionSpotlightIndexer.swift`
- Modify: `Offshoots/DecisionStore.swift` — add `var onChange: ((DecisionStoreChange) -> Void)?`, called from `add`, `update`, `delete(at:)`, `delete(_:)`, `deleteAll`, `replaceAll`, `resolveDecision`, `addRevisit`, `publishRestored`, after the mutation. Not called when `recoveryError != nil`.
- Modify: `Offshoots/OffshootsApp.swift` — build `WidgetSummaryWriter` in `init()` (`_widgetSummary = State(initialValue: writer)`); build `ShortcutsService(store:widgetSummary:)`; `AppDependencyManager.shared.add(dependency: service)`; set `store.onChange` to the indexer; run the startup sync once in a `.task` when the store is not blocked.
- Modify: `Offshoots/Shortcuts/DecisionEntity.swift` — add `@available(iOS 27.0, *) extension DecisionEntityQuery: IndexedEntityQuery`.
- Test: `OffshootsTests/DecisionSpotlightIndexerTests.swift`

**Interfaces:**
- Produces:
  ```swift
  enum DecisionStoreChange: Equatable { case upserted([UUID]), deleted([UUID]), replacedAll }
  @MainActor final class DecisionSpotlightIndexer {
      init(index: some DecisionSearchIndexing = CSSearchableIndex.default(), now: @escaping () -> Date = { .now })
      func handle(_ change: DecisionStoreChange, decisions: [Decision])
      func syncAll(decisions: [Decision], blocked: Bool)
  }
  protocol DecisionSearchIndexing: Sendable {   // CSSearchableIndex conforms in an extension
      func index(_ entities: [DecisionEntity]) async throws
      func delete(ids: [UUID]) async throws
      func deleteAll() async throws
  }
  ```
- `replacedAll` → delete all, then index all. `syncAll` with `blocked == true` does nothing.
- The `IndexedEntityQuery` methods call the same indexer path (`reindexEntities` → index the matching entities; `reindexAllEntities` → `syncAll`), and skip when blocked.

- [ ] **Step 1: Write the failing tests** (fake `DecisionSearchIndexing` that records calls)

```swift
@Test func storeReportsEachMutation() {
    var changes: [DecisionStoreChange] = []; store.onChange = { changes.append($0) }
    store.add(a); store.update(a2); store.delete(a2); store.replaceAll(with: [b]); store.deleteAll()
    #expect(changes == [.upserted([a.id]), .upserted([a.id]), .deleted([a.id]), .replacedAll, .replacedAll])
}
@Test func blockedStoreSkipsIndexing() {
    var changes: [DecisionStoreChange] = []; store.onChange = { changes.append($0) }
    store.blockAfterRestoreFailure(); store.add(a)
    #expect(changes.isEmpty)
    indexer.syncAll(decisions: [a], blocked: true); await fake.drain(); #expect(fake.calls.isEmpty)
}
@Test func replacedAllDeletesThenReindexes() async { /* fake.calls == [.deleteAll, .index([b.id])] */ }
@Test func resolveAndRevisitReindex() { /* resolveDecision and addRevisit each emit .upserted([id]) */ }
```

- [ ] **Step 2: Run to verify failure**

Run: `T -only-testing:OffshootsTests/DecisionSpotlightIndexerTests`
Expected: build fails, "value of type 'DecisionStore' has no member 'onChange'".

- [ ] **Step 3: Implement the hook, the indexer, the gated query extension, and the `OffshootsApp.init()` wiring**

- [ ] **Step 4: Run to verify pass**

Run: `T -only-testing:OffshootsTests/DecisionSpotlightIndexerTests -only-testing:OffshootsTests/DecisionStoreTests -only-testing:OffshootsTests/WidgetSummaryWriterTests`
Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add Offshoots/Shortcuts Offshoots/DecisionStore.swift Offshoots/OffshootsApp.swift OffshootsTests/DecisionSpotlightIndexerTests.swift
git commit -m "feat: index decisions in Spotlight and register ShortcutsService"
```

---

### Task 4: Intents and App Shortcuts

**Files:**
- Create: `Offshoots/Shortcuts/LogDecisionIntent.swift`
- Create: `Offshoots/Shortcuts/RecordOutcomeIntent.swift`
- Create: `Offshoots/Shortcuts/ShowRevisitsDueIntent.swift`
- Create: `Offshoots/Shortcuts/OpenDecisionIntents.swift` (`OpenDecisionIntent`, `OpenReadyToReviewIntent`)
- Create: `Offshoots/Shortcuts/OffshootsShortcuts.swift`
- Create: `Offshoots/Shortcuts/ShortcutsDialog.swift`
- Test: `OffshootsTests/ShortcutsIntentTests.swift`

**Interfaces:**
- Consumes: `ShortcutsService` (Task 1), `DecisionEntity` and enums (Task 2).
- Produces:
  ```swift
  enum ShortcutsDialog {   // pure; intents wrap the result in IntentDialog
      static func logged(_ d: Decision) -> LocalizedStringResource
      static func firstOutcome(_ d: Decision) -> LocalizedStringResource
      static func revisit(_ d: Decision, outcome: DecisionOutcome) -> LocalizedStringResource
      static func ready(_ ds: [Decision]) -> LocalizedStringResource
  }
  ```
- Intent type names, titles, descriptions, parameters, parameter summaries, and dialogs: spec §3a–§3d, verbatim. Type names are a public contract once shipped.
- `LogDecisionIntent.title` parameter is `String?` in code so `perform()` can `throw $title.needsValueError("What decision are you making?")` when it is nil or blank, before calling the service. Map `ShortcutsError.blankTitle` from the service the same way.
- Open intents: `openAppWhenRun = true` plus `@available(iOS 26.0, *) static var supportedModes: IntentModes { .foreground(.immediate) }`. `OpenReadyToReviewIntent.isDiscoverable = true`.
- App Shortcuts: spec §4 code block, verbatim.
- Formatted date in `logged`: `Date.FormatStyle(date: .abbreviated, time: .omitted)`.

- [ ] **Step 1: Write the failing tests**

```swift
@Test func dialogsMatchSpecCopy() {
    #expect(String(localized: ShortcutsDialog.ready([])) == "No decisions are ready to review right now.")
    #expect(String(localized: ShortcutsDialog.ready([a])) == "1 decision is ready to review: Take the job.")
    #expect(String(localized: ShortcutsDialog.ready([a, b, c])) == "3 decisions are ready to review, starting with Take the job.")
    #expect(String(localized: ShortcutsDialog.firstOutcome(resolvedGoodExpectedNeutral)) == "Recorded Good for \"Take the job\" (you expected Neutral).")
    #expect(String(localized: ShortcutsDialog.revisit(a, outcome: .good)) == "Added revisit: Good for \"Take the job\".")
}
@Test func intentsRequireAuthentication() {
    #expect(LogDecisionIntent.authenticationPolicy == .requiresAuthentication)
    #expect(RecordOutcomeIntent.authenticationPolicy == .requiresAuthentication)
    #expect(ShowRevisitsDueIntent.authenticationPolicy == .requiresAuthentication)
    #expect(OpenDecisionIntent.authenticationPolicy == .requiresAuthentication)
    #expect(OpenReadyToReviewIntent.authenticationPolicy == .requiresAuthentication)
}
@Test func openDecisionRoutesToDecision() async throws { /* pattern: LockScreenAndControlTests.openLogIntentRoutesToLog; expect .decision(id) */ }
@Test func openReadyToReviewRoutes() async throws { /* expect .readyToReview */ }
@Test func appShortcutsHaveThreeEntries() { #expect(OffshootsShortcuts.appShortcuts.count == 3) }
```

Do not call `perform()` on the three service-backed intents in tests: the hosted test app registers the real service, which writes to the simulator's journal. Their logic is covered in Task 1.

- [ ] **Step 2: Run to verify failure**

Run: `T -only-testing:OffshootsTests/ShortcutsIntentTests`
Expected: build fails, "cannot find 'ShortcutsDialog' in scope".

- [ ] **Step 3: Implement the dialogs, five intents, and `OffshootsShortcuts`**

Each service-backed `perform()` is `@MainActor`: value checks, then one service call, then `.result(value: DecisionEntity(...), dialog: IntentDialog(ShortcutsDialog...))`. `ShowRevisitsDueIntent` returns `[DecisionEntity]`.

- [ ] **Step 4: Run to verify pass, and build Release**

Run: `T -only-testing:OffshootsTests/ShortcutsIntentTests`
Expected: `** TEST SUCCEEDED **`.
Run: `DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -configuration Release -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **` with no App Intents metadata errors (`appintentsmetadataprocessor` warnings about phrases count as failures).

- [ ] **Step 5: Commit**

```bash
git add Offshoots/Shortcuts OffshootsTests/ShortcutsIntentTests.swift
git commit -m "feat: add Siri and Shortcuts intents and App Shortcuts phrases"
```

---

### Task 5: Donations and onscreen entity

**Files:**
- Modify: `Offshoots/LogDecisionView.swift` (`saveDecision()`, after `store.createDecision`)
- Modify: `Offshoots/MarkOutcomeView.swift` (`saveOutcome()`, after `guard saved`)
- Modify: `Offshoots/RevisitView.swift` (`saveRevisit()`, after a true `addRevisit` result)
- Modify: `Offshoots/DecisionDetailView.swift` (`body`)
- Create: `Offshoots/Shortcuts/ShortcutsDonation.swift`

**Interfaces:**
- Consumes: `LogDecisionIntent`, `RecordOutcomeIntent`, enums (Tasks 2, 4).
- Produces:
  ```swift
  enum ShortcutsDonation {
      static func loggedDecision(category: DecisionCategory, stakes: DecisionStakes)
      static func recordedOutcome(_ outcome: DecisionOutcome)
  }
  ```
- Each builds the intent with only those parameters set and calls `Task { try? await IntentDonationManager.shared.donate(intent:) }`. No title, notes, or `DecisionEntity`.
- `DecisionDetailView`: `.userActivity("com.geoffrey.silva.Offshoots.decision") { $0.appEntityIdentifier = EntityIdentifier(for: DecisionEntity(decision, now: .now)) }`. Add the activity type to `NSUserActivityTypes` in `Offshoots/Info.plist`.

No unit test covers donations or the user activity (system calls with no observable result in-process). Build only, then the Task 6 device checks.

- [ ] **Step 1: Implement `ShortcutsDonation` and the three call sites**
- [ ] **Step 2: Add the user activity and the `NSUserActivityTypes` entry**
- [ ] **Step 3: Build**

Run: `DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add Offshoots/Shortcuts Offshoots/LogDecisionView.swift Offshoots/MarkOutcomeView.swift Offshoots/RevisitView.swift Offshoots/DecisionDetailView.swift Offshoots/Info.plist
git commit -m "feat: donate Shortcuts intents and mark the open decision"
```

---

### Task 6: Verification and docs

**Files:**
- Modify: `CHANGELOG.md` (`## In Progress`), `TODO.md` (check off Stop 2 items with the date)

- [ ] **Step 1: Full suite (merge gate)**

Run: `T`
Expected: `** TEST SUCCEEDED **`. Report the pass/fail count.

- [ ] **Step 2: Archive check**

Run: `scripts/archive-upload.sh --archive-only`
Expected: archive succeeds.

- [ ] **Step 3: Simulator checks** (use the `verify-offshoots` skill, seeded with a fixture that has due decisions)

Run each check in spec "Simulator checks" and record pass or fail with a screenshot path. Neither Mac has a runtime older than iOS 27.0, so state that the iOS 18.6–26 paths were not run on a simulator.

- [ ] **Step 4: Update `CHANGELOG.md` and `TODO.md`; list the device checks from the spec as open items for Geoff (iPhone 17)**

- [ ] **Step 5: Commit**

```bash
git add CHANGELOG.md TODO.md
git commit -m "docs: record Shortcuts and Siri starter set"
```

- [ ] **Step 6: Hand off** — say the branch is `dev/shortcuts` in the main checkout, ready for Geoff to push and merge.
