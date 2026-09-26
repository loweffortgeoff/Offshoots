# TODO

## Next

## Backlog — remaining audit sections (see `docs/2026-09-23-audit-bugfixes-and-core-loop.md`)
- [ ] **VoiceOver summaries for the Insights charts.** Swift Charts read poorly with VoiceOver. Give each chart card a short spoken summary: totals, top category, outcome split, trend and prediction accuracy. From the unmerged `dev/offshoots-development` TODO (2026-04-29).
- [ ] **Log review date goes stale past midnight.** The Log form sets its review date to "tomorrow" once, when the tab is created, and again after each save. If the Log tab stays open past midnight, that date becomes today: no preset chip is selected, and a decision saved then is ready for review at once. This existed before the review-date presets; the chips only make it visible. Fix idea: reset the date to `ReviewDatePreset.tomorrow.date()` when the day changes (`store.today`) or when the Log tab appears, but only if the user has not picked a date. Found in the `early-engagement` branch review (2026-09-26).

## Done
- [x] **Calendar days cannot be tapped on Log and Edit.** Confirmed cause: the tap-outside-to-close-the-keyboard gesture from Section 5 sat on the whole form and took the day taps away from the calendar. Fixed by gating the gesture on focus, so it only intercepts taps while a text field is active. — 2026-09-26
  Checked on the iPhone 17 (iOS 27) by Geoff.
- [x] Merge `fix/calendar-day-taps` to `main` (fast-forward) — 2026-09-26
- [x] VoiceOver pass on the iPhone 17 with VoiceOver on: rows, the outcome picker and the Insights cards. Chunk 3 checked labels and traits in the accessibility tree only.
- [x] Merge `remove-tip-jar` to `main` (fast-forward) — 2026-09-26
- [x] Remove the Tip Jar: both Swift files, the Settings Support section and the StoreKit link (branch `remove-tip-jar`) — 2026-09-26
- [x] Draft `ASC_LISTING.md` for the 2.0.0 relaunch; replace the blanket `*.md` ignore with a Task(ed)-style `.gitignore` — 2026-09-26
- [x] Merge `screenshot-pipeline` to `main` (fast-forward) — 2026-09-26
- [x] Screenshot pipeline: app fixes, fixture, `scripts/screenshots.sh`, first 7-shot capture (branch `screenshot-pipeline`) — 2026-09-26
- [x] Merge `early-engagement` to `main` (fast-forward) — 2026-09-26
- [x] Early engagement, chunk 4: result line and progress copy (branch `early-engagement`) — 2026-09-26
- [x] **Early engagement: build it.** Run the plan `docs/superpowers/plans/2026-09-26-early-engagement.md` in a fresh session, subagent-driven (spec: `docs/superpowers/specs/2026-09-26-early-engagement-design.md`). Four chunks, each a review stop: review-date presets, a "So far" trend, starter suggestions, then a result line with progress copy. Keep the SwiftUI view work (the preset chip row and the Dashboard-to-Log pre-fill) inline; delegate the engine tasks. — 2026-09-26
- [x] Early engagement, chunk 3: starter suggestions (branch `early-engagement`) — 2026-09-26
- [x] Early engagement, chunk 2: "So far" trend (branch `early-engagement`) — 2026-09-26
- [x] Early engagement, chunk 1: review-date presets (branch `early-engagement`) — 2026-09-26
- [x] Merge `section-6-housekeeping` to `main` (fast-forward) — 2026-09-25
- [x] Audit section 6: Housekeeping — duplicate headers, header typo, stable chart and app-list ids, unused code removed, README structure (branch `section-6-housekeeping`) — 2026-09-25
- [x] Native Tip Jar carried over from `dev/offshoots-development` and merged; that branch deleted — 2026-09-25
- [x] Section 5 code review fixes (splash icon, dark Settings rows, Delete All wording) — 2026-09-25
- [x] Merge `section-5-ui` to `main` (fast-forward) — 2026-09-25
- [x] Section 5, chunk 6: App Theme picker, first-launch splash, Revisit pill (open question closed: add the pill) — 2026-09-25
- [x] Audit section 5: UI — 2026-09-25
- [x] Section 5, chunk 5: row context menu (Edit, Delete), JSON export, Delete All with confirmation — 2026-09-25
- [x] Section 5, all nine findings from the 2026-09-24 simulator run (chunks 1–4) — 2026-09-25
- [x] Section 5, chunk 4: sheet layout — keyboard closes on outside tap and Done (Revisit, Mark Outcome, Log, Edit); Save pinned above the keyboard; detail cards full width — 2026-09-25
- [x] Section 5, chunk 3: outcome picker and VoiceOver (labels, selected state, 60 × 68 pt targets, rows at accessibility sizes, decorative icons hidden) — 2026-09-25
- [x] Section 5, chunk 2b: Dynamic Type layouts — Insights cards, detail metadata and chart text work at accessibility sizes — 2026-09-25
- [x] Section 5, chunk 2a: Dynamic Type — no fixed font sizes; Quick Stats tiles equal height; dashboard and rows stack at accessibility sizes — 2026-09-25
- [x] Section 5, chunk 1: adaptive palette (contrast, Soil/Loam dark mode, category chart, Upcoming/Pending contrast, accent value for the date picker) — 2026-09-25
- [x] Merge `section-4-architecture` to `main` (fast-forward) — 2026-09-25
- [x] Unit tests pass on the iPhone 17 Pro (15 of 15, after fixtures moved into the test bundle) — 2026-09-25
- [x] Section 4 code review fixes (store created once, title reschedules reminder, test target hygiene) — 2026-09-25
- [x] Section 4, chunk 1: Swift 6 language mode; JSON storage decision — 2026-09-25
- [x] Section 4, chunk 5: README tech stack matches the code — 2026-09-25
- [x] Section 4, chunk 4: `@Observable` store with a stored `today` for review readiness — 2026-09-25
- [x] Section 4, chunk 3: all reminder scheduling goes through the store (Edit and Settings) — 2026-09-25
- [x] Section 4, chunk 2: `OffshootsTests` target and `AnalyticsEngine` tests — 2026-09-25
- [x] Audit section 1: bug fixes — 2026-09-23
- [x] Audit section 2: core loop (Ready to Review, notes, in-context permission, revisits) — 2026-09-23
- [x] Testing gate for sections 1–2 on the simulator (checks 1–5 pass) — 2026-09-24
- [x] Track `docs/` in git — 2026-09-24
- [x] Device check on the iPhone 17 Pro: the reminder arrives by itself and a tap opens the decision. Sections 1–2 testing gate closed — 2026-09-25
- [x] Merge `claude/sleepy-newton-ru1q7c` to `main` — 2026-09-25
- [x] Section 3 decision: outcome stats use the latest rating and accuracy uses the first — 2026-09-25
- [x] Section 3, chunk 2: resolved-date time windows, "Too early" trend, "Tied" top category — 2026-09-25
- [x] Section 3, chunk 3: Close accuracy, Optimism card, quality score removed, stakes weights left unused — 2026-09-25
- [x] Seed script `scripts/seed.sh` — 2026-09-25
- [x] Merge `section-3-insights` to `main` — 2026-09-25
- [x] Start CHANGELOG, DECISIONS, TODO — 2026-09-24
