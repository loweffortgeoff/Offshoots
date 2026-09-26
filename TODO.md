# TODO

## Next
- [ ] **Early engagement: build it.** Run the plan `docs/superpowers/plans/2026-09-26-early-engagement.md` in a fresh session, subagent-driven (spec: `docs/superpowers/specs/2026-09-26-early-engagement-design.md`). Four chunks, each a review stop: review-date presets, a "So far" trend, starter suggestions, then a result line with progress copy. Keep the SwiftUI view work (the preset chip row and the Dashboard-to-Log pre-fill) inline; delegate the engine tasks.
- [ ] Early engagement, chunk 3: starter suggestions
- [ ] Early engagement, chunk 4: result line and progress copy
- [ ] VoiceOver pass on the iPhone 17 Pro with VoiceOver on: rows, the outcome picker and the Insights cards. Chunk 3 checked labels and traits in the accessibility tree only.

## Backlog — remaining audit sections (see `docs/2026-09-23-audit-bugfixes-and-core-loop.md`)
- [ ] **VoiceOver summaries for the Insights charts.** Swift Charts read poorly with VoiceOver. Give each chart card a short spoken summary: totals, top category, outcome split, trend and prediction accuracy. From the unmerged `dev/offshoots-development` TODO (2026-04-29).
- [ ] **Design decision for Geoff: flatten the cards?** The April `dev/offshoots-development` TODO proposed moving away from raised rounded cards with shadows: flatten `PrimaryCard` and Quick Stats, make Insights and Decision Detail native sections, turn Log, Edit and Mark Outcome into native form sections, and drop the card framing on pending rows. This is a large visual change. Decide yes or no before any work starts.

## Done
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
