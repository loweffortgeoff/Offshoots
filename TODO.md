# TODO

## Next
- [ ] Section 5, UI — in progress on `section-5-ui` (see Backlog).

## Backlog — remaining audit sections (see `docs/2026-09-23-audit-bugfixes-and-core-loop.md`)
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
  - The Quick Stats "Outcomes" tile wraps "Good 100%" onto two lines, so the three tiles have different heights.
- [ ] **Section 5, open question.** A revisit-due row shows "Ready to revisit" but no "Review" pill. Keep it that way (the recommendation) or add the pill?
- [ ] **Section 6, Housekeeping.**
  - File header comments are duplicated.
  - Header typos: `NotificationDelegare`, `DasbboardView`.
  - The README project structure is out of date. It lists 12 files (one renamed since); the app now has 29.

## Done
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
