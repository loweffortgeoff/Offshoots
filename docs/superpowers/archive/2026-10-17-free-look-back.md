# Free Look Back Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans. Implement inline. Use one fresh whole-branch reviewer and a subagent for Xcode device interactions.

**Current status (2026-10-17):** Geoff accepted build 10 on his phone and approved the local merge to main. The original stop-at-device-testing instruction below records the implementation handoff; this approval supersedes that stop. Push and release actions remain separate.

**Goal:** Ship free deterministic Look Back in 2.0.0 and reserve the paid Reflection upgrade for November 2.1.0.

**Architecture:** Extract the existing statistics and bars into LookBack/. Build free results directly from decisions. Short-circuit ReflectionCenter.make before model, debug overrides, or StoreKit setup while the paid release switch is off.

**Tech Stack:** SwiftUI, Charts, Swift Testing; retained FoundationModels and StoreKit code remains dormant.

**Spec:** docs/superpowers/specs/2026-10-17-free-look-back-design.md

## Global Constraints
- iOS 18.6+ runtime; Xcode 27.1+ build. Only iPhone 18 Pro (iOS 27.0) simulator.
- Keep personal notes and stored decisions intact. Keep archived plans tracked and in place.
- Work on dev/free-look-back. Commit locally; no merge, push, upload, or submission.

## Review Focus
- Notes absent or model unavailable: free counts and bars still display immediately.
- Revisits change latest ratings: Look Back still uses the first outcomes.
- A category changes or gains a result: the card recomputes without stale output.
- Existing sandbox ownership or debug unlock flags: no paid production entry point.
- Small samples and mixed results: thresholds and honest no-headline behavior remain.

## Task 1: Free Look Back and dormant paid package
**Files:** LookBack/LookBackCard.swift, LookBackBars.swift, LookBackStats.swift, OutcomePair.swift; ReflectionDigest.swift, ReflectionDigestBuilder.swift, ReflectionCenter.swift, LogDecisionView.swift; LookBackStatsTests.swift and ReflectionReleaseTests.swift.
**Interfaces:** LookBackStats(category: String, pairs: [OutcomePair]) remains. Add LookBackStats.build(category: DecisionCategory, decisions: [Decision]) -> LookBackStats. ReflectionCenter.make(arguments: [String]) returns the dormant production center while disabled.
- [x] Run baseline tests on the allowed simulator.
- [x] Add a failing test that the production center exposes no paid controls or purchase setup.
- [x] Move existing statistics and bars without changing their rules. Test category, pending, full-history, no-note, and first-outcome behavior at the direct builder boundary.
- [x] Replace LookBackCard's model runner with immediate statistics and Copy. Remove its model gate in Log.
- [x] Add the default-off release switch before paid setup and debug flags. Verify normal/fake/unlock launch arguments remain dormant.
- [x] Run the whole suite and build Release.

## Task 2: Current listing and November cycle
**Files:** ASC_LISTING.md, RELEASE_NOTES.md, README.md, CHANGELOG.md, DECISIONS.md, TODO.md, CLAUDE.md, scripts/screenshots.sh, relevant Notebook entries.
**Interfaces:** 2.0 listing promises only free Look Back. 2.1.0 owns all deferred paid/model quality and IAP work.
- [x] Replace current paid listing claims and release tests. Preserve historical release evidence with clear version labels.
- [x] Consolidate paid quality, existing Look Back copying, note meaning, model fallback, purchase, and evaluation work under November 2.1.0.
- [x] Check ASC state and marketing screenshots. Keep IAP out of 2.0; prepare affected captures if needed. Preserve existing assets.
- [x] Record the approved decision and update the notebook's current-release/cycle guidance without rewriting unrelated content.

## Task 3: Verification and device handoff
- [x] Inspect seeded free Look Back, thresholds, category switching, personal notes, and absence of paid controls with Xcode interactions on the allowed simulator.
- [x] Capture light/dark and accessibility evidence with simctl io and inspect screenshots. Restore simulator appearance/text size after checks.
- [x] Obtain one whole-branch review. Fix material findings and run the checks their fixes require.
- [x] Record measured build/test/UI evidence, bump the testing build, and commit. Leave physical-device checks open. Stop at Ready for Geoff's device testing.


## Verification and device handoff — 2026-10-17
- Machine reported hostname `Mac`, macOS 27.0.1 (26A434), Xcode 27.1 (27A9275). Only iPhone 18 Pro, iOS 27.0, UDID `204520A6-E5B5-447D-8A6B-028317014DD8` was used.
- Baseline: 198 tests in 23 suites. Release-gate regression failed on the three intended assertions before the change. Final suite: 202 tests in 24 suites passed; Release simulator build passed. Logs/results: `/tmp/offshoots-free-look-back.67xFyz/`. Existing App Intents metadata warning remains; this app has no App Intents dependency.
- Debug UI: free Work/Home/Money counts, below-threshold Other, clear-lean headline, Copy clipboard text, category changes, first outcomes after revisits, standard light/dark and largest accessibility size in dark checked. Personal notes remained; Settings/Insights/Revisit showed no paid controls. Screenshots were captured with explicit-UDID simctl io.
- Release app built and launched. Its UI smoke check was blocked by a Cheque In location permission prompt on the shared simulator; that prompt was not touched. Physical-device runtime and VoiceOver listening remain Geoff's gates.
- Fresh whole-change review found no P1/P2 issues. The minor stale Settings description in README was corrected.
- Local listing copy is prepared. Remote ASC writes, IAP attachment/promotion checks, final marketing recapture/promotion, archive/upload/submission, and merge/push are outside this device-testing handoff. Two old Duo captures show paid controls; refresh the iPhone Log capture too. See TODO.
- Execution ruling: use the approved branch in the existing clean checkout; no added worktree. Keep the plan/spec tracked and in place after implementation. November 2.1.0 remains planned, not started.
- Original simulator decisions and preferences were restored byte-for-byte, with hash checks; appearance/text size restored and Xcode interaction session closed. Seven raw verification captures are saved under `ASC Screenshots/Offshoots/Captures/2026-10-17/free-look-back-verification/`; these are evidence/source captures, not promoted App Store images.
- Largest accessibility Look Back was inspected in dark mode. Light accessibility capture did not include the card; that combination remains part of device testing.

## Device acceptance and integration — 2026-10-17
- Geoff confirmed "Build 10 looks good on my phone" and authorized the local merge into main. No app code changed after device acceptance. The device gate is closed; the earlier simulator limitation remains historical evidence.
- Keep this plan/spec in place. Do not archive them automatically. November 2.1.0 remains the paid Reflection cycle.
- Integration verified: `main` fast-forwarded to `76107ed`, including the implementation and phone-acceptance docs. The merged app passed 202 tests in 24 suites; result bundle `/tmp/offshoots-build10-merge-76107ed.xcresult`. Push remains Geoff's step.
