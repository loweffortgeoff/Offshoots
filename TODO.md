# TODO

## Next
- [ ] Section 3 — decide first: should outcome stats (Good %, distribution chart) use the first rating or the latest revisit? Accuracy stays on the first rating.

## Backlog — remaining audit sections (see `docs/2026-09-23-audit-bugfixes-and-core-loop.md`)
- [ ] **Section 3, Insights correctness.**
  - Accuracy is exact-match only on a 5-point scale.
  - `numericValue` and the stakes weights are not used.
  - There is no optimism-bias metric, but the README promises one.
  - `decisionQualityScore()` is never shown.
  - Time windows use `createdAt`, not `resolvedAt`.
  - The trend shows "Stable" when there is too little data.
  - Top Category picks one category when counts are tied.
- [ ] **Section 4, Architecture.**
  - Move the store to `@Observable`/`@MainActor`.
  - Route all reminder scheduling through the store. Edit still calls `ReminderManager` directly.
  - Decide between JSON with schema versioning and SwiftData.
  - Add tests, starting with `AnalyticsEngine`.
  - `SWIFT_VERSION` is 5.0, but the README says Swift 6.
  - The test target deploys to 26.1, but the app deploys to 18.6.
- [ ] **Section 5, UI.**
  - Matcha `#A4C639` text has low contrast (about 2:1).
  - The dark palette is defined but not used.
  - The category chart colors are not from the palette.
  - The Appearance rows in Settings are placeholders.
  - There is no export or delete-all.
  - The 2-second splash shows on every launch.
  - Font sizes are hardcoded, so Dynamic Type does not apply.
  - Delete is only in the long-press menu.
- [ ] **Section 5, found by the 2026-09-24 simulator run.**
  - VoiceOver reads rating icons as generic symbol names ("Favorite", "Close").
  - The outcome picker always reports "Good" as selected.
  - The outcome picker touch targets are small (about 20–28 pt wide).
  - In the Revisit and Mark Outcome sheets, the keyboard does not close when you tap outside it and covers Save.
  - The Save Outcome button sits at the bottom edge of the screen when a follow-up is on.
  - Some detail cards are narrower than the rest.
  - The Upcoming header and the Pending badge have low contrast.
  - The date picker selection is black, not the accent color.
- [ ] **Section 5, open question.** A revisit-due row shows "Ready to revisit" but no "Review" pill. Keep it that way (the recommendation) or add the pill?
- [ ] **Section 6, Housekeeping.**
  - File header comments are duplicated.
  - Header typos: `NotificationDelegare`, `DasbboardView`.
  - The README project structure is out of date. It lists 12 files (one renamed since); the app now has 29.

## Done
- [x] Audit section 1: bug fixes — 2026-09-23
- [x] Audit section 2: core loop (Ready to Review, notes, in-context permission, revisits) — 2026-09-23
- [x] Testing gate for sections 1–2 on the simulator (checks 1–5 pass) — 2026-09-24
- [x] Track `docs/` in git — 2026-09-24
- [x] Device check on the iPhone 17 Pro: the reminder arrives by itself and a tap opens the decision. Sections 1–2 testing gate closed — 2026-09-25
- [x] Merge `claude/sleepy-newton-ru1q7c` to `main` — 2026-09-25
- [x] Start CHANGELOG, DECISIONS, TODO — 2026-09-24
