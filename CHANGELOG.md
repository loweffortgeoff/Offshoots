# Changelog

In-flight changes from coding sessions. The release pass turns these into release notes.

## Merged to `main` — branch `screenshot-pipeline`

### 2026-09-26 — Screenshot pipeline, stop 3
- First full capture pass: 7 dark-mode shots in `ASC Screenshots/Offshoots/Captures/2026-09-26/`.
- The status bar shows a plain full battery, not a charging bolt.
- The shot notes in `scripts/screenshots.sh` give the scroll position that worked for each shot.

### 2026-09-26 — Screenshot pipeline, stop 2
- `scripts/screenshots.sh` sets up the iPhone 18 Pro Max for App Store captures: dark mode, 9:41, seeded data moved to today, no splash.
- `docs/fixtures/screenshots.json` with `ScreenshotFixtureTests`, which pins every number the shots show.

### 2026-09-26 — Screenshot pipeline, stop 1
- The Outcomes legend on Insights always adds up to 100%. It used to cut off the decimals, so it could show 97%.
- The Optimism card reads "On average, you expect 0.5 steps better than the outcome you first mark, across 6 decisions." It used to say "than the first result".

## Merged to `main` — branch `early-engagement`

### 2026-09-26 — Early engagement, chunk 4
- Decision Detail shows how the first rating compared with the prediction for every marked decision, and what unlocks next while fewer than 6 are marked.
- Progress in place of empty states: the trend tile reads "N of 6 marked", the Optimism card counts toward 3, and empty Insights cards say "Mark your first outcome to see this."
- Outcome Trends says "No outcomes marked in the last 8 weeks." when there are marked outcomes but none recent.
- Empty Outcomes and Prediction Accuracy cards fill the width, like the other Insights cards.

### 2026-09-26 — Early engagement, chunk 3
- "Try a quick one" on the Dashboard: three small example decisions for new users. A tap fills in the Log form with the title, the category and a review tomorrow. The card goes away at 5 logged decisions.

### 2026-09-26 — Early engagement, chunk 2
- The trend shows earlier. With 6 or more marked decisions and not enough data for the 30-day windows, the Dashboard tile compares the older half with the newer half and reads "Trend · So far".

### 2026-09-26 — Early engagement, chunk 1
- Review-date presets (Tomorrow, 3 days, 1 week, 1 month) on Log and Edit Decision. A preset keeps the time of day, so reminder timing does not change.
- The four review-date presets fit on one row on the iPhone 18 Pro at the default text size; larger text sizes fall back to two rows, then a column.

## Merged to `main` — branch `section-6-housekeeping`

### 2026-09-25 — Audit section 6, Housekeeping
- Changed: nine source files had the Xcode header comment two or three times. Each file keeps one header now. The DashboardView header read "DasbboardView". (`NotificationDelegare` was already fixed in section 1.)
- Fixed: Outcome Trends chart data got a new random id on every redraw. Its id now comes from the week and the outcome group.
- Changed: the other-apps list in Settings uses the App Store ID as its id. Its old random id did not change between redraws, so this only follows the project rule that identity comes from the element.
- Removed: unused `SectionHeader` view, and the unused `deletePending(at:)` and `deleteCompleted(at:)` helpers in the Decisions list.
- Changed: the README project structure lists all 39 source files, grouped by screen, plus the tests, fixtures and seed script.

## Merged to `main` — branch `tip-jar-native`

### 2026-09-25 — Native Tip Jar (carried over from `dev/offshoots-development`)
- Changed: the Tip Jar opens as a screen pushed from Settings, not a sheet. It is a plain form with one row per tip and its price, a loading row, and a "Tip Jar Unavailable" state with Try Again. The green gradient background is gone.
- Changed: the Tip Jar uses the Soil and Loam backgrounds, like Settings.
- Source: commit `4655cdf` on the unmerged April branch. Its build-number change (3 to 1) was not carried over.

## Merged to `main` — branch `section-5-ui`

### 2026-09-25 — Audit section 5, UI: chunk 1, color foundation
- Changed: accent, outcome and background colors are adaptive asset-catalog colors. Light mode uses darker shades, so accent and outcome text reach 4.5:1 on white (Matcha was about 2:1). Dark mode uses the Matcha, Sage, Sand and Clay palette on the Soil and Loam backgrounds, which were defined before but not used.
- Fixed: the Upcoming header and the Pending badge are readable in light mode.
- Fixed: Deep Clay (Very Bad) is readable in dark mode (was 2.4:1 on Loam).
- Changed: accent buttons (Save, Mark Outcome, Revisit) use a solid fill. Their text is white in light mode and Soil in dark mode.
- Changed: all screens, cards, fields and the Settings form use the palette backgrounds.
- Changed: the Categories chart draws every bar in the accent color, not six off-palette colors. `CategoryBreakdownCard` has its own file.
- Fixed: Categories chart labels were black in dark mode, and kept their old color after a live switch between light and dark. The chart now rebuilds when the color scheme changes.
- Fixed: tied categories keep a stable order (by name). Before, they swapped places on each redraw.
- Fixed: `AccentColor` had no value. The date picker selection uses the accent on iOS 26.5. On iOS 27.0 the system draws it in the label color.

### 2026-09-25 — Audit section 5, UI: chunk 2a, Dynamic Type
- Changed: no fixed font sizes remain. Small icons use text styles. Large icons and the tip emoji use `@ScaledMetric`, so they keep their size at the default setting and scale with it.
- Changed: the Quick Stats tiles are one `QuickStatTile` view with equal heights. The Outcomes tile reads "Outcomes / 50% good", so the value no longer wraps.
- Changed: at accessibility text sizes, the dashboard header, the Quick Stats tiles, the Recent Decisions header and the decision rows stack vertically, so no word breaks in the middle.

### 2026-09-25 — Audit section 5, UI: chunk 2b, Dynamic Type layouts
- Added: `CardTitle`, one title row for the seven Insights cards. At accessibility sizes it drops the decorative icon and puts the note ("Last 30 days") under the title.
- Changed: at accessibility sizes the Overview grid is one column, the Outcomes legend sits under the ring, and the accuracy counts, the Optimism card and the detail screen's category, stakes and status stack.
- Changed: chart text stops growing at the largest non-accessibility size, because axis labels cannot wrap. Outcome Trends labels every second week above the default size.
- Known: the placeholder in the decision title field is cut off at accessibility sizes. SwiftUI draws a placeholder on one line. The Stakes segmented control does not grow with the text (system control).

### 2026-09-25 — Audit section 5, UI: chunk 3, outcome picker and VoiceOver
- Fixed: VoiceOver read the Good icon's checkmark as "Selected", so the outcome picker always sounded as if Good was chosen. The picker buttons now say the outcome, and only the chosen one is marked selected.
- Fixed: the picker's tap area is the whole tile (about 60 × 68 pt), not only the icon and text.
- Changed: at accessibility sizes the picker shows one full-width row per outcome.
- Fixed: rating icons read the outcome name, not the symbol name ("Favorite", "Close"). Rows read "Expected Bad, turned out Good". Revisit history reads "Bad to Good".
- Changed: decorative header and empty-state icons are hidden from VoiceOver.
- Changed: `OutcomePickerView` and `OutcomeButton` have their own file.

### 2026-09-25 — Audit section 5, UI: chunk 4, sheet layout
- Fixed: in Revisit and Mark Outcome, a tap outside a control or the keyboard's Done button closes the keyboard.
- Changed: the Save button in Revisit and Mark Outcome is pinned at the bottom. It stays above the keyboard and no longer sits at the screen edge when a follow-up is on.
- Fixed: on Log and Edit, a tap outside a text field did not close the keyboard. In Edit, Done did nothing while the notes field was focused.
- Fixed: every card on the decision detail screen takes the full width.

### 2026-09-25 — Audit section 5, UI: chunk 5, delete and data
- Changed: rows in the Decisions list have a context menu with Edit and Delete. It replaces a hidden long-press gesture that went straight to the delete alert.
- Added: Settings > Data > Export Decisions shares a JSON file in the same format as `decisions.json`.
- Added: Settings > Data > Delete All Decisions, with a confirmation. It also cancels every reminder.
- Changed: `decisions.json` is written with sorted keys, so the same decisions always give the same file. Existing files load unchanged.
- Added: store tests for the export and for Delete All (17 tests).

### 2026-09-25 — Audit section 5, UI: chunk 6, settings and launch
- Added: Settings > Appearance > App Theme picks System, Light or Dark. The placeholder App Icon row is gone.
- Changed: the splash ("Welcome to Offshoots") shows on the first launch only, not for 2 seconds on every launch.
- Added: a completed decision that is due for a revisit shows a "Revisit" pill, like the "Review" pill on a pending decision.
- Fixed: the first-launch splash showed an empty space instead of the app icon (`offshootsdar` was not an image set). It now uses a `splashicon` image set made from the dark app icon.
- Fixed: in dark mode, Settings rows used the system grey instead of the Loam card color. The row color is now set on each section.
- Fixed: the Delete All dialog reads "Delete 1 decision?" when one decision is left, not "Delete all 1 decisions?".
- Changed: Settings > We Also Make shows each app's real icon, with a light and a dark variant taken from that app's own icon set. The Task(ed) placeholder icon is gone. Muzzletoff is now listed as EveryPaw (same App Store ID).

## Merged to `main` — branch `section-4-architecture`

### 2026-09-25 — Audit section 4, Architecture
- Changed: the app builds in Swift 6 language mode (`SWIFT_VERSION` 5.0 to 6.0). No code changes were needed.
- Decided: keep JSON storage and add no schema version yet (see DECISIONS).
- Added: an `OffshootsTests` target (Swift Testing, iOS 18.6) with `AnalyticsEngine` tests built on the Insights fixtures.
- Added: a shared `Offshoots` scheme with a Test action.
- Changed: all reminder scheduling goes through `DecisionStore`. `update()` reschedules a pending decision's reminder when its review date changes. Settings calls `store.setRemindersEnabled(_:)`. Views no longer call `ReminderManager`.
- Added: `DecisionStore(saveURL:)` and store tests for save-then-load and for the backup of an unreadable file.
- Removed: `xcschememanagement.plist` from git (per-user Xcode state; the file stays on disk).
- Changed: `DecisionStore` is `@Observable` instead of `ObservableObject`. Views read it with `@Environment(DecisionStore.self)`. The store no longer imports Combine.
- Changed: review readiness is measured against the store's stored `today`, which moves forward when the app becomes active. `Decision.isReadyForReview` is now `isReadyForReview(asOf:)`, and rows get the result as a parameter.
- Docs: the README tech stack lists Observation and Swift Testing, and says Combine is used only by `NotificationDelegate`.
- Fixed: the store is created once, in `OffshootsApp`. Owned by `ContentView`, it decoded the file a second time when the splash ended.
- Fixed: editing a pending decision's title also updates its scheduled reminder, which shows the title.
- Changed: the test target signs with the app's team, and store tests delete their temporary folders. `Fixture` has its own file.
- Fixed: tests load fixtures from the test bundle, not a Mac file path, so they also pass on a device.

## Merged to `main` — branch `section-3-insights`

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
