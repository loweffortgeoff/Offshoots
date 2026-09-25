# Changelog

In-flight changes from coding sessions. The release pass turns these into release notes.

## Unreleased — branch `section-3-insights`

### 2026-09-25 — Audit section 3, Insights correctness
- Fixed: Good %, the Outcomes chart and Outcome Trends now use the latest revisit rating.
- Fixed: the trend and Outcome Trends group decisions by the date the outcome was marked, not the date the decision was logged.
- Fixed: the trend shows "Too early" when there is too little data, instead of "Stable". It now compares 30-day windows.
- Fixed: Top Category shows "Tied" on a tie, instead of a random pick.
- Changed: the Prediction Accuracy card gets its numbers from `AnalyticsEngine`, and its percentage now rounds the same way as the Overview tile.
- Added: the Prediction Accuracy card shows near misses (Close, one step off) apart from misses by two or more.
- Added: an Optimism card on Insights. It says whether your predictions run better or worse than the first result.
- Removed: the unused Decision Quality Score function and its README line.
- Added: `scripts/seed.sh` and Insights fixtures in `docs/fixtures/` for simulator checks.
- Moved four Insights cards out of `AnalyticsView.swift` into their own files (no behavior change).

## Merged to `main` — branch `claude/sleepy-newton-ru1q7c`

### 2026-09-25
- Device check passed on the iPhone 17 Pro (iOS 27.2 Beta 2). A real reminder arrived the next day and a tap opened the decision. The sections 1–2 testing gate is closed.

### 2026-09-24
- Ran the testing gate for audit sections 1 and 2. Simulator checks 1–5 pass on iOS 27.0. Results are in `docs/2026-09-23-audit-bugfixes-and-core-loop.md`.
- Tracked Markdown files under `docs/` in git (`.gitignore` exception).
- Started CHANGELOG, DECISIONS and TODO.

### 2026-09-23 — Audit sections 1 and 2
- Fixed: the detail screen now shows edits and outcomes at once. It no longer shows a stale copy.
- Fixed: tapping a reminder opens the Decisions tab and the right decision. This works for cold launch and repeat taps.
- Fixed: the Settings "Follow-up Reminders" toggle now cancels reminders when off and reschedules them when on.
- Fixed: an unreadable `decisions.json` is copied aside before the store can overwrite it.
- Fixed: you can no longer choose a review date in the past.
- Fixed: "See All" switches to the Decisions tab and no longer opens a second navigation stack.
- Fixed: completed rows show the date the outcome was marked (`resolvedAt`).
- Added: reminders show as a banner while the app is open.
- Added: a Ready to Review section on the Dashboard and the Decisions list, with a "Review" row badge.
- Added: an optional Notes field on the Log screen. Notes also show on the detail screen.
- Changed: the app asks for notification permission the first time it needs to schedule a reminder, not at launch.
- Added: revisits. You can re-rate a marked decision, add a note, and chain another revisit. A timeline shows each change.

## Before this changelog (from git history)
- 2025-12: first build. Decision tracking, dashboard, analytics, notifications, botanical color theme.
- 2026-01: Swift Charts insights, settings, decision editing, 5-point outcome scale, stakes, reflection, secondary follow-up, tip jar with 4 consumable purchases.
- 2026-03 to 2026-07: README, Settings cleanup, `.gitignore`.
