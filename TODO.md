# TODO

## Next
- [ ] Section 5, UI — in progress on `section-5-ui` (see Backlog).

## Backlog — remaining audit sections (see `docs/2026-09-23-audit-bugfixes-and-core-loop.md`)
- [ ] **Section 5, UI.**
  - The Appearance rows in Settings are placeholders.
  - The 2-second splash shows on every launch.
- [ ] **Section 5, open question.** A revisit-due row shows "Ready to revisit" but no "Review" pill. Keep it that way (the recommendation) or add the pill?
- [ ] **Section 6, Housekeeping.**
  - File header comments are duplicated.
  - Header typos: `NotificationDelegare`, `DasbboardView`.
  - The README project structure is out of date. It lists 12 files (one renamed since); the app now has 29.

## Done
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
