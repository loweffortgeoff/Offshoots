# Offshoots iOS — Audit, Bug Fixes & Core-Loop Work (Sep 23, 2026\)

## Summary

Full audit of the Offshoots iOS app (\~3,900 lines SwiftUI), grouped into six sections: bugs, core-loop gaps, Insights correctness, architecture, UI, housekeeping. Sections 1 and 2 were implemented and pushed; work paused before section 3\.

- **Repo / branch:** `loweffortgeoff/Offshoots` → `claude/sleepy-newton-ru1q7c` (pushed, 5 commits ahead of `main`, no PR opened)  
- **Diff:** 17 files changed, \+773 / −159

## Commits

1. `83ff71c` Fix section 1 audit bugs: stale detail, deep links, reminders toggle, data safety  
2. `cff69e0` Show follow-up reminders while the app is in the foreground  
3. `8627b69` Section 2: surface due reviews, capture notes up front, ask for reminders in context  
4. `63067ce` Remove unused ReminderManager.requestAuthorization  
5. `ec49912` Add revisit history: re-rate marked decisions and chain follow-ups

## Section 1 — Bugs (done)

- **Stale detail screen:** `DecisionDetailView` held a copy of the decision, so marking an outcome or editing didn't show until you backed out. Now reads the live decision from the store by ID.  
- **Reminder taps did nothing:** app never switched tabs; cold-launch and repeat taps were lost. `NotificationDelegate` now publishes `pendingDecisionID`; `ContentView` switches to Decisions and pushes the decision via a bound `NavigationPath`. Old NotificationCenter relay removed.  
- **Settings "Follow-up Reminders" toggle was decorative:** now honored — off cancels all pending reminders, on reschedules future ones; `ReminderManager` checks it before scheduling.  
- **Silent data-loss path:** unreadable `decisions.json` is copied to `decisions-unreadable-<timestamp>.json` before the empty store can overwrite it.  
- **Past review dates allowed:** Log picker minimum is tomorrow; Edit keeps an already-overdue date but won't move earlier.  
- **"See All" nested a second NavigationStack:** now switches to the Decisions tab.  
- **Completed rows showed the review date:** new `resolvedAt` field set when an outcome is marked (older decisions fall back).  
- **Extra:** reminders were suppressed while the app was open — added `willPresent` (banner, list, sound).

## Section 2 — Core loop (done)

- **Ready to Review:** decisions whose review (or revisit) day has arrived get a Dashboard section (hidden when empty), top section of the Decisions list (split into Ready / Upcoming / History), and a "Review" row badge. Store refreshes on return to foreground.  
- **Notes up front:** optional Notes field on the Log screen; notes now shown on the detail screen (previously only visible inside Edit).  
- **Permission prompt in context:** removed from launch; requested the first time a reminder is scheduled. Scheduling skipped if denied or if the toggle was switched off meanwhile.  
- **Revisits (Geoff's choice: rating \+ note kept as history, chainable):**  
  - New `Revisit` model (date, outcome, note); `Decision.revisits`, oldest first.  
  - First marked outcome stays in `actual` and remains the basis for prediction accuracy; `currentOutcome` (latest revisit) drives hero, title badge and list rows.  
  - `RevisitView` sheet: re-rate (defaults to last rating), "what changed" note, optional next revisit date. Button on detail screen always available, emphasized when due.  
  - Revisit timeline card on detail shows each change against the rating it replaced.  
  - `NextRevisitPicker` extracted and shared with Mark Outcome.  
  - Custom `Decodable` init defaults missing `revisits` (and `stakes`) so existing data loads unchanged.

## Testing

- **Not run.** Session ran in a Linux cloud container with no Swift toolchain or Xcode; nothing was compiled or run on device/simulator. Changes were checked by reading diffs only.

### Testing gate results (2026-09-24)

Run on the Mac mini: Xcode 27.0 (27A266a), iPhone 18 Pro simulator, iOS 27.0. Test data was backdated JSON written into the app's Documents folder, so no check waited on real time. No code changed.

1. **Build: pass.** Clean build, no Swift warnings. The device build (iPhone 17 Pro, iOS 27.2 Beta 2) also succeeds (Geoff).
2. **Existing data: pass.** A file saved before `stakes`, `revisits` and `resolvedAt` existed loads, and completed rows fall back to the review date. A corrupt file is copied to `decisions-unreadable-<timestamp>.json` before the store overwrites it. The phone had no install, so there was no real data to check on the device.
3. **Ready to Review: pass.** Overdue, due-today and due-revisit decisions show under Ready. A decision due tomorrow shows under Upcoming. Revisit and Mark Outcome update the detail screen at once and move the row to History. The revisit timeline shows each rating against the one it replaced.
4. **Reminder tap: pass.** The banner shows while the app is open. A tap opens the Decisions tab and the right decision in three cases: app in the foreground, app in the background and app killed. A repeat tap routes again.
5. **Reminders toggle: pass.** On a fresh install with the toggle off, logging a decision gives no permission prompt, so nothing is scheduled. Turning the toggle on asks for permission at that moment, because it reschedules pending decisions.

**Device check (2026-09-25): pass.** On the iPhone 17 Pro (iOS 27.2 Beta 2), a decision logged with tomorrow as the review date sent its reminder by itself. A tap opened that decision (Geoff). The gate is closed.

**Minor findings (not gate failures):**
- VoiceOver: rating icons read as generic symbol names ("Selected", "Favorite", "Close"). The outcome picker reports "Good" as selected whatever the actual choice.
- The outcome picker's touch targets are small (about 20–28 pt wide).
- The keyboard in the Revisit and Mark Outcome sheets does not close when you tap outside it, so it covers Save.
- With a follow-up turned on, the Save Outcome button sits at the bottom edge of the screen.
- Some detail cards are narrower than the full-width cards around them. The Upcoming header and the Pending badge have low contrast. The date picker selection is black, not the accent color.
- A revisit-due row shows "Ready to revisit" as its subtitle but no "Review" badge. Pending rows that are due do show one.

## Verify first in Xcode

1. Build — watch for concurrency warnings in `NotificationDelegate.swift` and the custom decoding in `Decision.swift` (project uses default MainActor isolation). New `ReadyToReviewSection.swift` and `RevisitView.swift` should be picked up by the synchronized group.  
2. Existing data still loads on a device with real decisions.  
3. Ready to Review: advance clock a day → Upcoming moves to Ready. Mark outcome with a 1-week revisit, advance a week → "Ready to revisit".  
4. Reminder tap: drag `{"aps":{"alert":"test"},"decisionID":"<UUID>"}` onto the simulator, app killed and backgrounded.  
5. Settings toggle off → log a decision → confirm nothing scheduled.

## Open decision for section 3

Should outcome stats (Good %, distribution chart) use the first rating or the latest revisit? Accuracy stays on the first rating.

**Section 3 — done 2026-09-25.** Outcome stats use the latest revisit rating (`currentOutcome`). Accuracy uses the first rating (`actual`). See DECISIONS.md.

## Remaining audit sections

- **3 — Insights correctness:** exact-match-only accuracy on a 5-point scale; unused `numericValue` and stakes weights; no optimism-bias metric (README promises one); `decisionQualityScore()` never shown; time windows use `createdAt` instead of `resolvedAt`; trend shows "Stable" with too little data. Section 3 — done 2026-09-25, see DECISIONS.md.  
- **4 — Architecture:** move store to `@Observable`/`@MainActor`; route all reminder scheduling through the store (Edit still calls `ReminderManager` directly); JSON \+ schema versioning vs SwiftData; add tests (start with `AnalyticsEngine`); `SWIFT_VERSION = 5.0` vs README's Swift 6; test target deployment 26.1 vs app 18.6. Section 4 — done 2026-09-25 on `section-4-architecture`, see DECISIONS.md.  
- **5 — UI:** Matcha `#A4C639` text/buttons \~2:1 contrast (fails WCAG AA); dark "Soil/Loam" palette defined but unused; off-palette category chart colors; placeholder Appearance rows in Settings; no export / delete-all; 2-second splash every launch; hardcoded font sizes (Dynamic Type); delete only via long-press.  
- **6 — Housekeeping:** duplicated file header comments; header typos (`NotificationDelegare`, `DasbboardView`); stale README project structure; no CHANGELOG / DECISIONS / TODO.

## Related Notes

- [Offshoots Web — Session Summary (Feb 28, 2026\)](http://Offshoots%20Web%20—%20Session%20Summary%20\(Feb%2028,%202026\).md)  
- [DecisionLoad\_RefactorPlan\_Checklist](http://DecisionLoad_RefactorPlan_Checklist.md)