# Hindsight Check-ins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for native execution, or superpowers:subagent-driven-development if Geoff chooses delegation. Steps use checkbox syntax for tracking.

**Goal:** Record what someone would repeat or change and let them inspect those answers across decisions without generated interpretation.
**Architecture:** Add optional answers to the existing Decision and Revisit JSON. Derive one dated entry per answered decision. Reuse the existing one-time StoreKit product through a separate Hindsight access object; retain generated Reflection and its disabled gate.
**Tech Stack:** SwiftUI, Observation, Foundation/Codable, StoreKit 2, Swift Testing. No new dependency or store.
**Spec:** `docs/superpowers/specs/2026-10-24-hindsight-check-ins-design.md` (approved by Geoff, 2026-10-24).
**Status:** Geoff approved native execution on 2026-10-24. Tasks 1–5 local implementation and verification are complete; the independent review corrective pass is verified. Phone, real-history usefulness, and customer-copy gates remain open. Production activation is not approved.

## Global Constraints

- Existing deployment minimum: iOS 18.6. No Apple Intelligence, PCC, or internet requirement for local Hindsight use.
- Exact answers: Same approach / Different approach / Different choice / Not sure. No default selection. Skipped is not Not sure.
- Reuse the existing optional review/revisit note. Existing outcome tracking, revisits, notes, timelines, analytics, and free Look Back remain free.
- No new logging field, tab, schedule, journal, mood scale, generated prose, score, or advice.
- Retain existing generated-Reflection implementation/evaluation; do not activate or delete it. Keep `ReflectionCenter.paidFeaturesEnabled` false.
- Keep saved answers, counts, filters, and exports readable regardless of ownership. Require verified ownership only for new structured capture.
- Keep new production purchase/capture disabled until Geoff accepts local/device evidence and reviews customer copy. Permit Debug-only evaluation without enabling generated Reflection.
- Stay on the existing `dev/paid-reflection` branch. Commit locally. No PR, push, merge, upload, ASC change, or release action.
- Use only iPhone 18 Pro (iOS 27.0), UDID `204520A6-E5B5-447D-8A6B-028317014DD8`, on every simulator call. Refresh inventory if that UDID is absent; do not substitute another device.
- Follow the project contract: Dynamic Type, VoiceOver selected state, full labels, stable element IDs, theme-aware controls, one substantial view/type per file, no extra confirmation for ordinary saves.

## Review Focus

1. Ownership revoked during an open form: retain the full draft and write nothing until the optional answer is cleared or ownership restored (Tasks 2–3).
2. Product loading, Restore, or verification fails: do not confuse an unavailable store with a verified refund or unlock a new owner from unverified data (Task 2).
3. A skipped or backdated revisit: keep the latest recorded answer and its original outcome/date together (Tasks 1 and 4).
4. Imported answers with no purchase: retain read/filter/export access; reject unknown enum values without partial replacement (Tasks 1 and 4).
5. A decision is edited/deleted while a review or list is open: preserve unknown added fields on edit, avoid stale navigation, and never attach an answer to a missing decision (Tasks 1, 3–4).

## Verification commands

Use Xcode.app on the Mac mini. Keep logs verbose; do not use `-quiet`. Replace `<Suite>` with a suite named in the owning task. Select the entire suite; a method filter without parentheses selected zero Swift tests during the PCC session.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Offshoots.xcodeproj -scheme Offshoots \
  -destination 'platform=iOS Simulator,id=204520A6-E5B5-447D-8A6B-028317014DD8' \
  -parallel-testing-enabled NO -only-testing:OffshootsTests/<Suite> test
```

Run the same command without `-only-testing` for the regular suite. Live model diagnostics stay off. Enable only the existing local StoreKit test gate when the acceptance task calls for it. Report executed/passed/skipped counts from the result bundle; zero selected tests is not a pass.

## Task 1: Persist answers and derive the dated review records

**Files:** Create `Offshoots/Hindsight/HindsightAnswer.swift`, `HindsightEntry.swift`, `HindsightSummary.swift`; modify `Offshoots/Decision.swift`, `DecisionStore.swift`, and `EditDecisionView.swift` only if its copy path drops new fields. Add `OffshootsTests/HindsightDataTests.swift`, `HindsightSummaryTests.swift`; extend `ReflectionBackupTests.swift` and `DecisionStoreTests.swift`.

**Interfaces:**
- `enum HindsightAnswer: String, Codable, CaseIterable, Identifiable, Equatable, Hashable`: stable raw values `sameApproach`, `differentApproach`, `differentChoice`, `notSure`; computed `label` and explanatory `detail` match the spec.
- `Decision.hindsight: HindsightAnswer?` represents the first review. `Revisit.hindsight: HindsightAnswer?` represents that revisit. Add default-nil initializer parameters and optional decoding. Keep existing IDs, dates, notes, and ratings.
- Add trailing `hindsight: HindsightAnswer? = nil` to `DecisionStore.resolveDecision(...)` and `addRevisit(...)`. Save the provided value on that event; a missing decision cannot receive an answer. Existing callers remain source-compatible.
- `struct HindsightEntry: Identifiable, Equatable`: `id` is `decisionID`; retain `decisionID`, `revisitID: UUID?`, `title`, `date`, `answer`, `outcome`, `note`. First-review date uses `resolvedDate`; revisit date uses its own date.
- `HindsightSummary.entries(from: [Decision]) -> [HindsightEntry]`; `count(_ answer: HindsightAnswer, in entries: [HindsightEntry]) -> Int`; `filtered(_ entries: [HindsightEntry], answer: HindsightAnswer?, outcome: DecisionOutcome?) -> [HindsightEntry]`.

- [x] **1. Write the domain/data failures.** Use temp-folder stores and hand-authored encoded data. Assert legacy files produce nil answers; every enum round-trips on first review and multiple revisits; unknown enum strings throw in decision-only and full-backup imports. After `waitForPendingSaves()`, reopen and compare answers/notes. Verify a legacy replacement leaves answers absent and current export/full backup preserve them. Keep failed imports from replacing either store. Verify editing only title/category retains answers and existing free notes.
- [x] **2. Write the summary failures.** Hand-build A with first Bad + Different approach, then Good + no answer: A must remain Bad + Different approach at its first-review date. B has Good + Different choice, then Bad + Same approach: B contributes only its last answer and paired Bad. C has Not sure; D has nil: total is 3, Not sure is 1, nil is excluded. Combined Same approach + Bad returns B only; Different choice + Bad is empty. Duplicate dates use later recorded array position. A backdated last recorded revisit still wins, matching `currentOutcome`'s existing array-order semantics. Pending decisions contribute nothing.
The skipped-revisit test includes these independently expected assertions:

```swift
var d = Decision(title: "Time away", category: .work, expected: .good,
    actual: .bad, followUpDate: Date(timeIntervalSince1970: 1_000),
    hindsight: .differentApproach)
d.revisits = [Revisit(date: Date(timeIntervalSince1970: 2_000), outcome: .good)]
let entries = HindsightSummary.entries(from: [d])
#expect(entries.count == 1)
#expect(entries.first?.answer == .differentApproach)
#expect(entries.first?.outcome == .bad)
#expect(entries.first?.date == Date(timeIntervalSince1970: 1_000))
#expect(HindsightSummary.filtered(entries, answer: .differentApproach, outcome: .good).isEmpty)
```

- [x] **3. Run `HindsightDataTests` and `HindsightSummaryTests` RED.** New tests may initially fail to compile because types are absent. Once interfaces exist, confirm their assertions reject missing persistence and wrong-event pairing; do not count a typo/import error as behavioral RED.
- [x] **4. Implement the interfaces.** Select the last answered revisit in recorded array order, else the first review's answer. Do not infer from notes or sort the decision's revisit history. Sort the cross-decision result by event date descending, tie by decision UUID. Preserve source IDs for later navigation. Reuse the existing JSON encoder/import and backup paths; no schema-version change is needed for optional fields.
- [x] **5. Verify GREEN and the full regular suite.** Include deletion, round-trip backup, rollback, and unchanged prediction/outcome analytics. Run the frozen source/digest tests: adding hindsight must not change model prompts or generation eligibility. Commit `feat: persist dated hindsight answers`.

## Task 2: Reuse ownership without model eligibility

**Files:** Create `Offshoots/Hindsight/HindsightAccess.swift` and `Offshoots/Reflection/EntitlementSnapshot.swift`; modify `ReflectionEntitlement.swift`, `ReflectionPurchase.swift`, and affected entitlement test doubles. Add `OffshootsTests/HindsightAccessTests.swift` and test-only `HindsightTestEntitlementSource.swift`; extend `ReflectionEntitlementTests.swift`, `ReflectionPurchasePolicyTests.swift`, and `ReflectionStoreKitIntegrationTests.swift` where shared behavior changes.

**Interfaces:**
- `struct EntitlementSnapshot: Equatable`: `verifiedProductIDs: Set<String>`, `revokedProductIDs: Set<String>` (default empty), `hasVerificationFailure: Bool`. Provide `init(verifiedProductIDs: Set<String>, revokedProductIDs: Set<String> = [], hasVerificationFailure: Bool)`. Verified revocations from transaction updates take precedence over uncertainty for the same accepted product; another accepted valid product may still grant ownership. The test source exposes mutable `snapshot` plus `push(_ snapshot:)` for listener tests. Change the existing source methods to `currentSnapshot() async -> EntitlementSnapshot` and `updates() -> AsyncStream<EntitlementSnapshot>`; adapt their existing fakes rather than adding a second entitlement source.
- `ReflectionEntitlement` keeps `isUnlocked`; add a resolved/unknown indication for truthful pending UI. An accepted verified ID grants ownership. A clean snapshot without accepted IDs removes it. Verification uncertainty with no accepted verified ID preserves prior verified ownership but grants nothing to an unknown person. Never store a bare unlock flag as independent proof.
- `@MainActor @Observable final class HindsightAccess`: owns optional `entitlement` and `purchase`, exposes `isEnabled`, `canCapture`, and `performSave(answer: HindsightAnswer?, save: (HindsightAnswer?) -> Void) -> Bool`. This synchronous main-actor boundary calls `save` only for nil or current verified ownership. False retains all form state and causes no store mutation.
- `HindsightAccess.init(isEnabled: Bool, entitlement: ReflectionEntitlement?, purchase: ReflectionPurchase?)` supports dependency injection. `showsInsights(hasSavedAnswers: Bool) -> Bool` returns enabled-or-saved-data, independent of ownership. `HindsightAccess.make(arguments: [String] = ProcessInfo.processInfo.arguments)` supplies a separate default-false release gate. Disabled production creates no StoreKit work. Read visibility is based on saved data, not this flag. Debug `-HindsightPreview` and `-HindsightLocked` cannot purchase; `-HindsightStoreKit` uses the real local test entitlement/purchase path.
- Extend `ReflectionPurchase.init` with defaulted `featureName: String = "Reflection"` and `purchaseBlockedMessage: String` retaining its current Reflection default. Hindsight passes `Hindsight` and a model-independent local feature gate through the existing `canPurchase` closure. That closure checks rollout eligibility, not existing ownership; a nonowner must be able to buy. Keep the exact accepted product ID `com.geoffrey.silva.Offshoots.reflection`.

- [x] **1. Write access failures.** Test accepted verified ownership without model availability; initial unknown + verification failure remains locked; verified owner + uncertainty stays owned; clean empty/refund snapshot locks; new verified owner unlocks. Product-load and Restore errors must not mutate entitlement. A delayed older refresh must not reinstate ownership after a newer verified revocation. Test that listener startup does not lose an update.
- [x] **2. Write save-boundary failures.** With a real temp DecisionStore, revoke ownership after a draft is created. `performSave` must return false, invoke no store write, and preserve draft answer/note/outcome. Clearing the answer allows the free save; restored ownership saves the original answer. Nil always permits free save. Debug locked preview cannot buy. Disabled Release construction leaves generated Reflection hidden and new Hindsight capture/purchase absent.
The uncertainty test starts from a verified owner and asserts the actual entitlement state:

```swift
let id = "com.geoffrey.silva.Offshoots.reflection"
let source = HindsightTestEntitlementSource(snapshot: EntitlementSnapshot(
    verifiedProductIDs: [id], hasVerificationFailure: false))
let entitlement = ReflectionEntitlement(source: source)
await entitlement.refresh()
#expect(entitlement.isUnlocked)
source.snapshot = EntitlementSnapshot(verifiedProductIDs: [], hasVerificationFailure: true)
await entitlement.refresh()
#expect(entitlement.isUnlocked)
source.snapshot = EntitlementSnapshot(verifiedProductIDs: [], revokedProductIDs: [id], hasVerificationFailure: true)
await entitlement.refresh()
#expect(!entitlement.isUnlocked)
```

- [x] **3. Run the relevant suites RED, then implement.** Keep a single shared StoreKit transaction source. Use `Transaction.currentEntitlements` for locally verified ownership; keep product availability separate. Ignore unverified transactions for new unlocks. Refresh/listener sequencing must prevent an older async result from overwriting a newer snapshot; subscribe before an initial refresh can miss updates. Verified refund/update paths must not become sticky offline ownership.
- [x] **4. Verify GREEN and the full regular suite.** Keep existing Reflection purchase/Restore behavior and ownership tests passing with default copy parameters. New Hindsight restore messages use its supplied name. Commit `feat: add model-independent Hindsight access`.

Apple's reference: [current entitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements) lists owned products and excludes refunded/revoked products; [Transaction verification](https://developer.apple.com/documentation/storekit/transaction) distinguishes verified from unverified results. Do not invent a network-only entitlement requirement or a custom license service. Offline relaunch behavior still needs device evidence.

## Task 3: Capture and read answers in existing flows

**Files:** Create `Offshoots/Hindsight/HindsightCheckInSection.swift`, `HindsightAnswerPicker.swift`, `HindsightHistoryLabel.swift`, `FirstOutcomeReflectionCard.swift`, `HindsightPurchaseSheet.swift`, and `HindsightPurchaseControls.swift`. Modify `OffshootsApp.swift`, `MarkOutcomeView.swift`, `RevisitView.swift`, `DecisionDetailView.swift`, `RevisitHistoryCard.swift`; update affected previews. Add `OffshootsTests/HindsightCaptureTests.swift` for the shared save boundary plus persistence.

**Interfaces:**
- Inject one app-owned `HindsightAccess` with `.environment(...)`. Start its entitlement work separately from `reflection.start()` and refresh on normal foreground entry; never create a generator for Hindsight.
- `HindsightCheckInSection(answer: Binding<HindsightAnswer?>, access: HindsightAccess)` shows either the optional picker or the explicit purchase entry. `HindsightAnswerPicker(selection: Binding<HindsightAnswer?>)` renders four full labeled choices, no default, and a Clear answer action. It does not own a note or another Save action.
- `HindsightHistoryLabel(answer: HindsightAnswer, date: Date)` is read-only and ownership-independent.
- `FirstOutcomeReflectionCard(note: String?, hindsight: HindsightAnswer?, date: Date?)` replaces the current free-note card with the same content/style when hindsight is nil. A first answer with no note must still appear. Move existing card code without unrelated styling changes.

- [x] **1. Write capture failures.** Exercise the production `performSave` boundary with both `resolveDecision` and `addRevisit`: default nil, all four answers, explicit Not sure, and cleared answers. Verify a new revisit starts nil rather than copying the previous value, first-review data remains unchanged, and ownership loss never partially saves the free outcome or note. Delete the source before Save and verify no record or answer is created. Check current-field edits preserve old answers.
- [x] **2. Run `HindsightCaptureTests` RED; implement the capture UI.** Keep the existing free note field. Switch only its prompt to `What would you keep or change?` when an answer is selected. Before Save, call `performSave` and invoke the existing store method inside its synchronous closure; do not await between authorization and mutation. On false, keep the form open and all input intact. Show inline ownership guidance with Restore and Clear answer actions. Never open a purchase sheet because Save was tapped. A free save after clearing still needs only the ordinary Save tap.
- [x] **3. Complete purchase presentation and history UI.** Implement `HindsightPurchaseSheet(purchase: ReflectionPurchase)` and `HindsightPurchaseControls(purchase: ReflectionPurchase, dismiss: () -> Void)` now so the capture entry has a complete, buildable destination. Use a labeled authored example, StoreKit price, pending/error/Restore states, and no AI promise; keep buying disabled in fixture previews. Reuse this sheet in Task 4. Then add history UI. Display first answer/date with its original outcome and free note. Add answer labels beside their own revisit events with full notes. Reading these fields has no entitlement gate. Keep recorded order; no emotional drift verdict. Extract touched substantial view fragments into named View types and avoid increasing bucket files. Do not modify existing free navigation or reminders.
- [x] **4. Verify GREEN and the full regular suite.** Build the Debug app on the explicit simulator destination. Confirm previews include the new environment dependency. Commit `feat: add hindsight to outcome reviews and revisits`.

## Task 4: Add the cross-decision review and honest purchase UI

**Files:** Create `Offshoots/Hindsight/HindsightInsightsSection.swift`, `HindsightReviewView.swift`, `HindsightDecisionRow.swift`, `HindsightSettingsSection.swift`. Modify `AnalyticsView.swift`, `SettingsView.swift`, and their previews. Add `OffshootsTests/HindsightReviewTests.swift` for record selection/filter transitions and visibility policy; extend release/ownership regressions as needed.

**Interfaces:**
- `HindsightInsightsSection(entries: [HindsightEntry])` reads access from the environment. Show this section after the existing outcome cards, including empty Insights when Hindsight is enabled. When production capture is disabled, show it only if saved answers exist. Compute entries once at the containing screen boundary; do not pass whole Decision objects to rows.
- `HindsightReviewView(entries: [HindsightEntry])`: four answer counts, optional answer filter, optional five-value outcome filter, and one row per matching decision. Counts/`N decisions with a recorded answer` refer to the full supplied entries; filters affect only the list and show `M shown`. Tapping a selected answer count again clears it. No filter means all; Not sure is an explicit filter. Count zero is valid.
- `HindsightDecisionRow(entry: HindsightEntry)` identifies the answer's outcome/date and opens that decision by ID resolved from the current store. If the decision disappeared, remove it/stop navigation safely rather than opening a stale struct. A pushed detail reads the current record while keeping the selected check-in identifiable by date.
- Reuse Task 3's purchase sheet and controls with Hindsight copy. Use a clearly labeled authored structured example, StoreKit `displayPrice`, one-time wording, and explicit free-feature boundaries. No AI output sample or hardware/language restriction.

- [x] **1. Write review failures.** Assert visibility for enabled owner/nonowner with zero data, disabled production with zero data, and a former owner/importer with saved data. Counts and filters remain readable for the last group. Confirm one entry needs no threshold, Not sure is counted, nil is absent, filters combine/reset, and deletion/import recomputes counts rather than retaining a cached source. Use Task 1's independent expected records, not results calculated by the same summary function.
- [x] **2. Run `HindsightReviewTests` RED; implement review UI.** With no saved answers, a nonowner's explicit Insights entry opens purchase. With saved answers, open the review without purchase; offer purchase only for new capture. Owners with no answers see useful review/revisit guidance. Keep all existing free cards and the two-pane arrangement intact. Use native navigation, menus, and selection controls rather than a new tab/chart/dashboard.
- [x] **3. Connect purchase and Settings.** Show purchase only on explicit entries. Add a separate Hindsight Settings section with ownership and Restore whenever the feature is enabled; retain generated Reflection's disabled UI. Preserve pending purchase state and clear error/retry messages. Final name/price are not chosen here; working UI says Hindsight and always shows StoreKit's price. Keep purchase buttons disabled in fixture previews. Do not touch ASC or change product IDs.
- [x] **4. Verify GREEN and the full regular suite.** Confirm frozen generated-Reflection release tests remain green and both feature gates are independent. Commit `feat: review hindsight across decisions`.

## Task 5: Validate the complete feature and hand off before activation

**Files:** Add `docs/fixtures/hindsight-check-ins.json` and `docs/hindsight-evaluation.md`; update fixture tests, README.md, CHANGELOG.md, DECISIONS.md, TODO.md. Add `OffshootsTests/HindsightStoreKitIntegrationTests.swift` gated by `HINDSIGHT_STOREKIT=1`; reuse the existing StoreKit test product resource.

- [x] **1. Create synthetic fixtures.** Include Same approach + Bad, Different choice + Good, Different approach with a note, explicit Not sure, unanswered reviews, skipped later answers, tied/backdated revisits, no-note answers, and long notes. Label authored examples as synthetic. Do not convert the Ghost PTO conversation into an invented rating or claim it repairs the missing exact model-regression fixture.
- [x] **2. Exercise local StoreKit.** Verify existing accepted-product ownership unlocks Hindsight without model eligibility, Restore works, refund blocks new capture while data stays readable/exportable, unknown/pending states do not unlock, and an open draft survives revocation. Use actual `SKTestSession` transactions and the real access/store boundary. Run with `TEST_RUNNER_HINDSIGHT_STOREKIT=1` and the explicit simulator destination; inspect every assertion. Do not equate a session API purchase with a purchase-button or phone sandbox check.
- [x] **3. Run the complete regular suite and Release build.** Use the verification command above without a suite filter, then with `-configuration Release build` and the same explicit destination. Inspect test counts and first errors; do not report skipped diagnostics as passes. Verify Debug flags are absent/ignored in Release, generated Reflection remains hidden, and saved hindsight stays readable even with sale/capture disabled.
- [x] **4. Inspect the running Debug app.** Open the allowed device panel and app. Follow the repository's Xcode interaction workflow; its required interaction subagent must target only the allowed simulator. Seed synthetic JSON after terminating the app; back up and restore its original data/preferences. Capture with `xcrun simctl io 204520A6-E5B5-447D-8A6B-028317014DD8 screenshot <path>`. Check Mark Outcome, Revisit, history, first answer without note, cleared answer, ownership-loss guidance, combined filters, current decision links, Settings, and purchase light/dark at default/largest text. Confirm free flows have one note field and no surprise paywall. Never tap Buy in fixture mode.
- [ ] **5. Complete remaining acceptance gates.** Local evidence is recorded. The following phone and paid-value checks remain open. Report automated/local StoreKit, simulator visuals, physical-device/VoiceOver, and phone sandbox purchase/Restore/refund separately. With Geoff, inspect real histories and check whether the comparisons add value beyond free notes. Record the customer name/price/copy as awaiting review. Before any sale, the system StoreKit product name and listing must match the approved package; do not change remote metadata in this implementation. Document that Hindsight avoids model-quality gates, not usability or paid-value acceptance.
- [x] **6. Update docs and commit the handoff.** Keep production capture/sale disabled and saved data readable. Leave completed plans/specs tracked in place. Do not move or archive them. Do not push or merge. A later explicit activation/release approval is required. Commit `test: verify Hindsight capture review and ownership`.

## Plan self-review

Spec coverage: Task 1 owns compatibility and event pairing; Task 2 owns offline/verified access; Task 3 owns optional capture and history; Task 4 owns counts, filters, navigation, and purchase entries; Task 5 owns local/device evidence and activation boundaries. All five Review Focus items have named checks in their owning tasks.

Implementation choices made here: preserve existing revisit array-order semantics; list counts keep a stable full-data denominator while `M shown` reports filtering; use the existing purchase controller with feature-specific copy; keep both production gates disabled during evaluation. The approved design permits these engineering choices. No new product scope or external tracker change is authorized by this plan.
