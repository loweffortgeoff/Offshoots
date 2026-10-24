# Paid Reflection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for native implementation or superpowers:subagent-driven-development if Geoff selects delegation. Steps use checkbox (`- [ ]`) syntax for tracking. Geoff approved this plan and native execution on 2026-10-24. Physical acceptance and production activation remain separately gated.

**Execution status:** Tasks 1–8 have local implementation and test evidence. Final review and artifact checks are in progress. Missing real-note inputs and physical-device quality leave Task 9 acceptance and Task 10 activation open.

**Goal:** Deliver useful, evidence-linked Patterns and decision readings that users generate deliberately and retain as dated history.

**Architecture:** Keep the existing SwiftUI, Foundation Models, and StoreKit seams. Add typed evidence to the generator boundary and a separate local JSON reading store. A request controller captures source data, runs generation, validates references, and saves accepted output without replacing history.

**Tech Stack:** Swift 6, SwiftUI, Observation, Foundation Models, StoreKit 2, Swift Testing, local JSON.

**Spec:** [Approved design](../specs/2026-10-24-paid-reflection-design.md).

## Global Constraints

- Free Look Back stays free on all supported devices. Preserve its first-outcome counts, bars, and immediate display.
- App deployment floor remains iOS 18.6. Model generation stays behind SDK availability checks and model/locale readiness. Build with Xcode 27.1 or later.
- Use only iPhone 18 Pro (iOS 27.0) for simulator work. Pass its exact UDID on every simulator command. Do not operate another device without current-session approval.
- No scheduled generation, monthly reviews, advice, personality labels, cloud service, analytics, third-party dependency, or subscription.
- Generate and refresh only on request. Retain saved readings and their evidence without silent rewriting.
- Keep the existing product ID `com.geoffrey.silva.Offshoots.reflection`. Saved content remains readable and deletable after refund or model loss.
- Keep production paid features disabled until Geoff accepts physical-device quality evidence. Add Debug-only evaluation access without bypassing the Release switch.
- Require zero factual reversals, meaning changes, or prompt leaks. Require at least 90% useful eligible outputs. Target 95% of physical-device requests within 10 seconds.
- Follow Dynamic Type, VoiceOver, theme-aware controls, stable identity, and one substantial type per file. Extract a touched type from a bucket file without unrelated behavior changes.
- Branch from current local `main` as `dev/paid-reflection` at execution time. Commit locally after each passing chunk. No PR, push, merge, upload, submission, or public release is authorized by this plan.

## Review Focus

- Duplicate or unknown evidence references must not make one decision look like multiple supporting decisions. Task 2 tests this.
- A source edit, deletion, refund, or import during generation must not let a late answer save against invalid current state. Task 4 tests this.
- A damaged saved-history file must remain recoverable and must not be silently overwritten. Task 3 tests this.
- A failed restore between two file writes must not leave a mixed journal and reading history after relaunch. Task 6 tests this.
- Empty current decisions must not hide saved Patterns whose original source records were deleted. Task 5 tests this.

## Execution and verification

Read README, CHANGELOG, DECISIONS, TODO, this plan, and the approved spec before execution. Check the machine, Xcode version, working tree, and branch. Do not overwrite unrelated changes.

Discover the exact iPhone 18 Pro / iOS 27.0 UDID from `xcrun simctl list devices available -j`. Use that value as `<IPHONE_18_PRO_IOS_27_UDID>` below. Do not select a similarly named device on another OS.

Unit command: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'platform=iOS Simulator,id=<IPHONE_18_PRO_IOS_27_UDID>' -parallel-testing-enabled NO test -only-testing:OffshootsTests/<Suite>`.

Replace `<Suite>` with each named suite in its task. Expected result: `TEST SUCCEEDED`, with the intended cases executed. Leave build output verbose. New Swift Testing cases must fail for the intended missing behavior before the implementation step, then pass. A compile failure from a missing new type is acceptable only for the initial API introduction.

For a UI check, open the named device in the Device panel when available. Use the project-required Xcode device-interaction workflow for taps and `xcrun simctl io <IPHONE_18_PRO_IOS_27_UDID> screenshot <path>` for captures. The project requires a subagent for those interactions. Do not claim physical-device quality from simulator or fake output.

## File and interface map

Keep new production types under `Offshoots/Reflection/` or its `History/` and `Evaluation/` subfolders. Keep tests in `OffshootsTests/`. Add files to the app/test targets if the project does not pick them up automatically.

- `ReflectionEvidence.swift`: Codable/Equatable evidence key with decision UUID, note stage, and revisit UUID where applicable. Model references are request-local keys resolved by code.
- `ReflectionSourceSnapshot.swift`: Codable/Equatable selected source records, plus eligible decision IDs for Patterns scope. Preserve exact original records separately from bounded prompt selection.
- `ReflectionObservation.swift`: Codable/Equatable stable observation ID, text, and resolved evidence keys. Observations never use mutable text as SwiftUI identity.
- `History/SavedReflection.swift`: Codable/Equatable/Identifiable dated reading with stable UUID, kind, typed content, and source snapshot.
- `History/ReflectionHistoryStore.swift`: Observable local history with injectable file access for failure tests. Commit in-memory changes only after successful atomic writes.
- `History/ReflectionFreshness.swift`: pure comparison of saved source records with current decisions; identifies changed, missing, and newly eligible records.
- `ReflectionRequestController.swift`: MainActor request ownership, timeout, cancellation, latest-request token, validated save, and non-destructive error state.
- `ReflectionBackup.swift` and `JournalDataCoordinator.swift`: versioned full-backup codec and coordinated replacement of decisions/history. Preserve existing decision-only codecs.
- `Evaluation/ReflectionEvaluationCase.swift`: offline case definition, hard-failure rubric, eligibility, and expected sources. Evaluation results stay out of the user's reading store.

Keep `ReflectionGenerating.patterns(digest:)`, `reflect(on:)`, and `cleanUp(note:)` as the generator seam. Retain dormant generated Look Back compatibility only where existing tests need it; do not reconnect it to Log.

## Task 1: Establish the evaluation before changing generation

**Files:** Create `docs/fixtures/reflection-acceptance.json`, `docs/reflection-evaluation.md`, `Offshoots/Reflection/Evaluation/ReflectionEvaluationCase.swift`, `OffshootsTests/ReflectionEvaluationCaseTests.swift`. Modify `OffshootsTests/ReflectionLiveOutputTests.swift`.

**Interfaces:** `ReflectionEvaluationCase` decodes a stable case ID, surface, source decisions, eligible/abstention classification, expected evidence, prohibited facts, and human scoring notes. `ReflectionEvaluationCase.load(from: Data) throws -> [ReflectionEvaluationCase]` rejects duplicate IDs and malformed references.

- [ ] Add failing codec tests for duplicate IDs, unknown expected decision IDs, and missing eligibility. Include an assertion that three notes on one decision do not qualify as cross-decision support.
- [ ] Run `ReflectionEvaluationCaseTests` and confirm the intended failure.
- [ ] Implement the codec and assemble 30–50 scored cases covering spec examples A–E, sparse/unrelated data, cross-category evidence, changing outcomes, long notes/histories, supported languages, and command-like text. Label synthetic cases. Locate exact Groceries, Ghost PTO, More Ghost PTO, and copying records; never invent their contents. If absent, keep those cases explicitly pending and report that evidence gap.
- [ ] Extend the opt-in live harness to record case ID, device/OS, model availability, prompt scope, duration, raw output, displayed output, and error/cancellation status. Capture raw and displayed output from the same model response, not two requests assumed to match.
- [ ] Document scoring: hard failure for invented facts, reversed meaning/ratings, prompt leaks, or invalid evidence; useful eligible output must add a specific supported observation. Score justified abstention separately. Count eligible empty/filtered/error results against usefulness and timeouts against latency; never count skipped model runs as passes.
- [ ] Run the codec suite and collect a pre-change baseline where the real model is available. Record unavailable hardware/model as unmeasured. Commit the evaluation foundation locally.

## Task 2: Preserve evidence identity and stop forced observations

**Files:** Create `ReflectionEvidence.swift`, `ReflectionSourceSnapshot.swift`, `ReflectionObservation.swift`. Modify `ReflectionDigest.swift`, `ReflectionDigestBuilder.swift`, `ReflectionEligibility.swift`, `ReflectionOutput.swift`, `ReflectionPromptBuilder.swift`, `LiveReflectionService.swift`, `FakeReflectionGenerator.swift`, and their existing digest/eligibility/output/prompt test suites. Extract touched substantial output types from `ReflectionOutput.swift` into named files.

**Interfaces:** `ReflectionSourceSnapshot.capture(decisions: [Decision], subjectID: UUID?) -> ReflectionSourceSnapshot`; `ReflectionObservation.validated(against: ReflectionSourceSnapshot, minimumDecisions: Int) throws -> ReflectionObservation`. `PatternsOutput.observations` is `[ReflectionObservation]`; decision output retains a summary and optional supported observations. Preserve source-compatible dormant Look Back values or update all their callers/tests in this task.

- [ ] Add failing tests: multiple notes from one decision fail recurring support; two distinct cross-category decisions may qualify; unknown or duplicate model keys cannot establish support; first outcome stays distinct from later revisits; ordering is deterministic on tied dates; unrelated records allow abstention.
- [ ] Run `ReflectionDigestBuilderTests`, `ReflectionEligibilityTests`, `ReflectionOutputTests`, and `ReflectionPromptBuilderTests` and confirm intended failures.
- [ ] Capture exact source records and request-local evidence keys. Include note stage and dated outcome context in prompts. Sort selected records deterministically. Count distinct decisions rather than note fields for Patterns eligibility. Use at least two evidence-bearing marked decisions as the generation minimum; remove the old five-marked-decisions requirement that is unrelated to evidence quality.
- [ ] Change generated schemas to optional observations with evidence references. Resolve keys against this request only. Reject unknown keys and observations with fewer than two distinct supporting decisions when they claim recurrence. Keep decision chronology calculations in code. Do not require a sentence per outcome group, a repeat, echo, or next question.
- [ ] Budget instructions, schema, selected records, and response against the available context. Drop whole evidence units or whole records instead of cutting notes mid-meaning. Report selected/omitted scope. If one note cannot fit intact, exclude it explicitly or decline generation; do not silently paraphrase it. Availability-gate newer token-count APIs and use conservative tested budgeting on older supported model OS versions.
- [ ] Update fake outputs and the live harness to the new types. Keep arbitrary prose validation claims honest: structural evidence validation does not establish semantic truth. Use the case evaluation for unsupported meaning and causal claims.
- [ ] Run the named suites plus the fixture and free `LookBackStatsTests` suites. Review the case results against the baseline. Commit the evidence/generation chunk locally.

## Task 3: Persist immutable readings and source history

**Files:** Create `History/SavedReflection.swift`, `History/ReflectionHistoryStore.swift`, `History/ReflectionFreshness.swift`, `OffshootsTests/ReflectionHistoryStoreTests.swift`, and `OffshootsTests/ReflectionFreshnessTests.swift`.

**Interfaces:** `SavedReflection` stores `id: UUID`, `generatedAt: Date`, `kind: Kind` (`patterns` or `decision(UUID)`), content, and snapshot. `ReflectionHistoryStore.init(saveURL: URL)` loads local data; `append(_ reading: SavedReflection) throws`, `delete(id: UUID) throws`, and `replaceAll(with: [SavedReflection]) throws` write atomically before publishing changes. `ReflectionFreshness.status(for: SavedReflection, decisions: [Decision]) -> ReflectionFreshness` returns changed/missing/newly-eligible IDs.

- [ ] Add failing tests for encode/decode with ISO 8601 dates, two refreshes preserving separate IDs/dates, relaunch persistence, untouched journal text, failed append/delete retaining previous disk and memory state, and unreadable-file preservation with writes blocked until explicit recovery.
- [ ] Run `ReflectionHistoryStoreTests` and confirm the intended failure.
- [ ] Implement a versioned `reflections.json` file with an injectable write failure seam. A missing file means empty history. An unreadable/unknown-version file means a visible recovery error, not permission to overwrite it. Keep the file and provide a recovery export path.
- [ ] Add freshness tests for source note edits, changed ratings, new revisits, deleted sources, added eligible Patterns decisions, and unchanged saved text/evidence. Implement comparisons against exact snapshots; do not use process-randomized hashes as persistent fingerprints.
- [ ] Run both new suites and commit the history chunk locally.

## Task 4: Control requests without losing saved content

**Files:** Create `ReflectionRequestController.swift`, `OffshootsTests/ReflectionRequestControllerTests.swift`. Modify `ReflectionCenter.swift`, `ReflectionGate.swift`, `ReflectionViewState.swift`, `ReflectionGenerating.swift`, and gate/run tests.

**Interfaces:** `ReflectionRequestController.start(kind: SavedReflection.Kind, decisions: [Decision])`, `cancel()`, and read-only request status. Inject generator, history store, clock/timeout, and current entitlement/source checks. Leave `ReflectionRun` available for unsaved Clean Up Note. Separate `canGenerate` from `canReadHistory`.

- [ ] Add failing tests for failed refresh retaining prior content; cancelled/empty/unsupported results saving nothing; save failure showing an unsaved result and error; refund or journal replacement during a request preventing append; source edits during a request invalidating its save; and stale responses from an older request being ignored.
- [ ] Run `ReflectionRequestControllerTests` and confirm intended failures.
- [ ] Implement generation from a captured snapshot. Before saving, recheck request token, entitlement, cancellation, and source state. Save exactly once after validation. A source change requires a fresh user request; never automatically restart.
- [ ] Use a 20-second request deadline as an implementation default, separate from the 10-second quality target. Timeout returns control and ignores late completions even if the provider ignores cancellation. Do not use a structured race that still waits for an uncooperative losing task. Prevent unbounded overlapping provider calls while one is still draining.
- [ ] Keep saved content readable when unsupported, not ready, refunded, or locked. Gate new generation/refresh/cleanup. Preserve ownership and Restore. Add Debug-only fake/live evaluation configuration ahead of the dormant-production return only in Debug builds; Release must still skip model/StoreKit setup while disabled.
- [ ] Run controller, gate, entitlement, run, and `ReflectionReleaseTests` suites. Commit the request/recovery chunk locally.

## Task 5: Add saved readings and inspectable evidence to the UI

**Files:** Modify `OffshootsApp.swift`, `PatternsCard.swift`, `DecisionReflectionCard.swift`, `ReflectionStateView.swift`, `AnalyticsView.swift`, `DecisionDetailView.swift`. Create `History/ReflectionHistoryView.swift`, `History/SavedReflectionView.swift`, `History/ReflectionEvidenceView.swift`, and `ReflectionObservationView.swift`. Move the touched private `ResultBody` out of `DecisionReflectionCard.swift` before changing it.

**Interfaces:** App owns one history store and provides it through the environment. `ReflectionHistoryView(kind: SavedReflection.Kind?)` presents dated entries. `SavedReflectionView(readingID: UUID)` resolves its saved record by stable ID. Evidence rows resolve current decisions by UUID and show retained source evidence when missing/changed.

- [ ] Add a small view-policy test suite for visibility with saved history but no current decisions, no entitlement, or no model. Saved content must remain reachable in all three cases. Verify no model call on history access or source changes.
- [ ] Run that suite and confirm the intended failure. Implement the visibility policy independently of current eligibility and the old `.hidden` generation gate.
- [ ] Wire Generate/Refresh/Cancel to the controller. Keep the latest saved reading visible while loading or displaying errors. Add dated history and confirmed reading deletion. Use source-change labels and an “At generation” evidence section. A source link opens the current record; a deleted source has an explanatory state.
- [ ] Expose all saved readings from Insights history, including decision readings whose subject was deleted. Do not add a top-level tab. New eligible decisions flag Patterns for refresh without generating automatically.
- [ ] Inspect fake success, no evidence, empty history, changed/deleted sources, unavailable model, failed save/refresh, and refund on the allowed simulator. Check light/dark, largest Dynamic Type, VoiceOver labels, long localized notes, and layout changes that rebuild a view. Reopening the view must recover saved content without a request.
- [ ] Run affected suites and a simulator build. Capture the running UI and commit the UI chunk locally.

## Task 6: Back up, restore, and delete the new local data coherently

**Files:** Create `ReflectionBackup.swift`, `JournalDataCoordinator.swift`, `ReflectionBackupExport.swift`, `OffshootsTests/ReflectionBackupTests.swift`, `OffshootsTests/JournalDataCoordinatorTests.swift`, and `SettingsDataSection.swift`. Modify `DecisionStore.swift`, `SettingsView.swift`, `DecisionsListView.swift`, `DecisionDetailView.swift`, and existing import/store tests. Keep `DecisionsExport.swift` and `DecisionsImport.swift` decision-only formats compatible.

**Interfaces:** `ReflectionBackup.encode(decisions: [Decision], readings: [SavedReflection]) throws -> Data`; `ReflectionBackup.decode(_ data: Data) throws -> ReflectionBackup`. `JournalDataCoordinator.restore(_ backup: ReflectionBackup) throws`, `importDecisions(_ decisions: [Decision]) throws`, and `deleteAll() throws` coordinate both stores, in-flight invalidation, and reminder reconciliation.

- [ ] Add failing round-trip tests for decisions/readings/evidence, old decision arrays, unknown backup versions, duplicate record IDs, and invalid evidence keys. Permit a saved source snapshot whose live decision was intentionally deleted.
- [ ] Run `ReflectionBackupTests` and confirm intended failures. Implement a versioned full-backup envelope with ISO 8601 dates and explicit full-backup actions. Preserve existing decision-only export/import behavior and labels.
- [ ] Add coordinator tests for replacing both stores, decision-only replacement clearing history, deleting all when decisions are empty but history exists, and invalidating in-flight generation. Inject failure before/between writes; after relaunch the journal and reading store must represent the same completed transaction.
- [ ] Implement coordinated writes with staged files and a small recoverable transaction marker. Drain prior decision writes before replacement, restore both old files on failure, and resolve an interrupted transaction before loading stores on launch. Publish memory state and reschedule/cancel reminders only for a completed transaction. This is local file coordination, not a new database layer.
- [ ] Extract the Settings Data section and import state into `SettingsDataSection.swift` as a move-only change before adding backup actions. Add clear full-restore/decision-only-replacement confirmations. Warn that decision-only import clears saved readings, even when no current decisions exist. Delete All clears both stores and cancels reminders with confirmation.
- [ ] Update every single-decision deletion confirmation, including list/context menu paths: retained excerpts remain in saved readings. Single deletion does not remove saved history. Ensure full backup/import and history deletion remain available without ownership/model access.
- [ ] Run backup/coordinator/import/store suites and inspect export, restore, cancelled restore, single deletion, and Delete All on the allowed simulator. Commit the backup/data-lifecycle chunk locally.

## Task 7: Prove Clean Up Note preserves meaning

**Files:** Modify `CleanUpNoteRow.swift`, `ReflectionPromptBuilder.swift`, cleanup generation in `LiveReflectionService.swift`, the acceptance fixture, and prompt/output/run tests.

**Interfaces:** Keep `ReflectionGenerating.cleanUp(note: String) async throws -> CleanedNote` and explicit Use/Dismiss. Do not save a generated-reading entry for cleanup.

- [ ] Add cases for negation, names, amounts, comparisons, intent, and the exact 2026-10-01 command-like note when available. Pin Use/Dismiss and changed-input behavior: stale suggestions cannot overwrite edited text.
- [ ] Run affected suites and record the pre-change live cleanup scores.
- [ ] Tune cleanup instructions and bounded request behavior against those cases. Keep model output separate from original text until acceptance. Do not claim a heuristic proves semantic equivalence. Failed physical-device meaning preservation blocks shipping cleanup.
- [ ] Run the case set and existing suites. Record any remaining failure explicitly; do not silently remove a promised paid row. Commit the accepted cleanup work locally.

## Task 8: Align the purchase and ownership experience

**Files:** Modify `UnlockReflectionSheet.swift`, `ReflectionSettingsSection.swift`, `ReflectionPurchase.swift`, `ReflectionGateView.swift`, gate/entitlement tests, and evaluation evidence. Extract the fixed example and purchase controls into named files before changing them.

**Interfaces:** Reuse `ReflectionPurchase` and the existing product ID. The sample is a fixed, scored generated reading with labeled synthetic sources. Reading history has no purchase gate; generation controls do.

- [ ] Add policy tests for ownership/Restore visibility during model loss, generation blocked after refund, saved history still readable/deletable, and no live personal preview before purchase.
- [ ] Run relevant suites and confirm intended failures.
- [ ] Replace free Look Back charts and the pre-decision paid row with a scored model-generated sample demonstrating the two core benefits and saved history. State model/device requirements, at least two distinct note-bearing decisions for Patterns, and what is usable with current data. Keep unavailable devices from purchasing a currently unusable generator while leaving Restore and history visible.
- [ ] Inspect the purchase sheet with fake/sample output at light/dark and accessibility sizes. Validate local StoreKit purchase/Restore/refund; report physical sandbox evidence separately. Commit the purchase chunk locally.

## Task 9: Final evaluation and handoff for device acceptance

**Files:** Update `docs/reflection-evaluation.md`, README, CHANGELOG, DECISIONS, TODO, and the plan checkboxes. Add focused regression tests only for failures discovered here.

- [ ] Run the complete unit suite once with the exact allowed simulator destination and a Release build with the same explicit destination. Require `TEST SUCCEEDED` and `BUILD SUCCEEDED`; report skipped live-model checks separately.
- [ ] Run all 30–50 cases on supported physical hardware. Score raw/displayed output, evidence, eligible usefulness, abstention, cleanup fidelity, and latency. Include the exact recorded real-note failures before claiming the acceptance gate passed. Keep controlled evaluation output separate from user history.
- [ ] Check persistence through relaunch, changed/deleted source navigation, backup/restore, interrupted restore recovery, unavailable model/locale, purchase/Restore/refund, and accessibility on physical devices. Record device, OS, and the tested build.
- [ ] Request a fresh whole-branch code review after tests pass. Address findings within this feature and rerun only affected checks. Update docs with actual evidence and remaining blockers. Commit the final verification record locally.
- [ ] Stop for Geoff's acceptance of quality evidence. Keep production paid features disabled if the gate has not passed. No release claims follow from local tests alone.

## Task 10: Activate only after quality acceptance

**Files:** `ReflectionCenter.swift`, `ReflectionReleaseTests.swift`, and release-facing docs/metadata files used by the existing release workflow.

- [ ] After Geoff accepts the physical-device evidence and authorizes activation, update the production paid-feature switch and its tests. Preserve Debug override safety and iOS/model availability checks. Run the full suite and Release build for the activated configuration.
- [ ] Prepare IAP metadata, review screenshot, listing, and marketing screenshots through the existing release skills. Show customer-facing copy for review. Keep free Look Back excluded from paid claims.
- [ ] Hand off local commits and build evidence. Geoff handles push. Merge, archive/upload, submission, and public release each require their own authorization.

## Self-review and recommended execution

Spec coverage: evidence and chronology → Task 2; saved immutable history/freshness → Task 3; manual generation/failures/access → Task 4; navigation/accessibility → Task 5; deletion/export/import → Task 6; cleanup fidelity → Task 7; purchase honesty → Task 8; scored evaluation and physical acceptance → Tasks 1 and 9; gated activation → Task 10.

All five Review Focus conditions have a named owning test task. New interfaces are defined above before their consumers. The existing six roadmap phases remain the tracker view; these tasks split their implementation into testable chunks.

Recommend native implementation in this thread with a fresh whole-branch review. The evidence, request, history, and backup tasks share interfaces and benefit from one implementation context. Wait for Geoff's plan review and execution-method selection before creating the feature branch or editing app code.
