# Changelog

In-flight changes from coding sessions. The release pass turns these into release notes.

## In Progress

#### Added
- Settings > Data > Import Decisions restores an Export Decisions file. An empty app imports at once. Otherwise it asks "Replace N decisions with M from the file?" first. A wrong file shows "This file is not an Offshoots export." Old reminders are cancelled and the imported decisions' future reminders are scheduled.
- Reflection, an optional $5.99 one-time unlock with Restore in Settings. Patterns on Insights, a reflection on Decision Detail, and Clean Up Note on the Log, Mark Outcome and Revisit note fields. The text comes from the on-device model, so nothing leaves the phone. It needs Apple Intelligence on iOS 26 or later; other devices do not see Reflection.

#### Changed
- iPad: the app window now resizes freely, up to the phone width that iPadOS allows (about 512 pt). Before, it snapped between two fixed sizes. The app stays iPhone-only. The deprecated `UIRequiresFullScreen` flag is removed.
- Reflection: the purchase sheet no longer says "not charged" when the purchase is unverified. The paywall keeps its pending state and clears the old Restore message. A control that is not ready says "Reopen the app in a little while." The Settings footer now covers text generation only. The Import picker shows "unreadable" for a file it cannot read.
- Reflection: Restore Purchase is full width at accessibility text sizes.
- Reflection: the "Unlock Reflection" sheet has a new look. A leaf logo sits above a centered intro. The three features share one card with dividers and green symbols, with the footnote "Nothing appears until you tap for it." The buy and Restore Purchase buttons stay at the bottom. At accessibility text sizes they scroll with the content, so they do not cover the card. The price still comes from the App Store and stays inside the button. Purchase logic is unchanged.

#### Fixed
- The header meta row on Decision Detail stacks from the xxLarge text size up. At larger sizes the "Neutral" rating wrapped as "Neu-tral".
- At accessibility text sizes, the revisit rows on Decision Detail broke the rating ("Good") and the date into one-letter columns. Each row now stacks the icons, the rating and the date at accessibility sizes, and keeps the side-by-side layout at other sizes. `RevisitHistoryCard` has its own file.

---

## Shipped

### 2.0.0 — It Keeps Going After You Decide

_Revisits, Ready to Review, review-date presets, a result line and starter suggestions, plus Insights that count revisits, a full UI and accessibility pass, and the Tip Jar removed. Release pass prepared 2026-09-26. Baseline: every commit after `0e29c15`, the 1.0 upload (2026-01-04)._

#### Added
- Revisits. You can re-rate a marked decision, add a note, and chain another revisit. A timeline shows each change.
- A Ready to Review section on the Dashboard and the Decisions list, with a "Review" row badge.
- A completed decision that is due for a revisit shows a "Revisit" pill, like the "Review" pill on a pending decision.
- An optional Notes field on the Log screen. Notes also show on the detail screen.
- Reminders show as a banner while the app is open.
- Review-date presets (Tomorrow, 3 days, 1 week, 1 month) on Log and Edit Decision. A preset keeps the time of day, so reminder timing does not change.
- The four review-date presets fit on one row on the iPhone 18 Pro at the default text size; larger text sizes fall back to two rows, then a column.
- "Try a quick one" on the Dashboard: three small example decisions for new users. A tap fills in the Log form with the title, the category and a review tomorrow. The card goes away at 5 logged decisions.
- Decision Detail shows how the first rating compared with the prediction for every marked decision, and what unlocks next while fewer than 6 are marked.
- The Prediction Accuracy card shows near misses (Close, one step off) apart from misses by two or more.
- An Optimism card on Insights. It says whether your predictions run better or worse than the first result.
- Settings > Appearance > App Theme picks System, Light or Dark. The placeholder App Icon row is gone.
- Settings > Data > Export Decisions shares a JSON file in the same format as `decisions.json`.
- Settings > Data > Delete All Decisions, with a confirmation. It also cancels every reminder.
- `CardTitle`, one title row for the seven Insights cards. At accessibility sizes it drops the decorative icon and puts the note ("Last 30 days") under the title.

#### Changed
- The app asks for notification permission the first time it needs to schedule a reminder, not at launch.
- The trend shows earlier. With 6 or more marked decisions and not enough data for the 30-day windows, the Dashboard tile compares the older half with the newer half and reads "Trend · So far".
- Progress in place of empty states: the trend tile reads "N of 6 marked", the Optimism card counts toward 3, and empty Insights cards say "Mark your first outcome to see this."
- Outcome Trends says "No outcomes marked in the last 8 weeks." when there are marked outcomes but none recent.
- The Optimism card reads "On average, you expect 0.5 steps better than the outcome you first mark, across 6 decisions." It used to say "than the first result".
- The Prediction Accuracy card gets its numbers from `AnalyticsEngine`, and its percentage now rounds the same way as the Overview tile.
- Accent, outcome and background colors are adaptive asset-catalog colors. Light mode uses darker shades, so accent and outcome text reach 4.5:1 on white (Matcha was about 2:1). Dark mode uses the Matcha, Sage, Sand and Clay palette on the Soil and Loam backgrounds, which were defined before but not used.
- Accent buttons (Save, Mark Outcome, Revisit) use a solid fill. Their text is white in light mode and Soil in dark mode.
- All screens, cards, fields and the Settings form use the palette backgrounds.
- The Categories chart draws every bar in the accent color, not six off-palette colors. `CategoryBreakdownCard` has its own file.
- No fixed font sizes remain. Small icons use text styles. Large icons and the tip emoji use `@ScaledMetric`, so they keep their size at the default setting and scale with it.
- The Quick Stats tiles are one `QuickStatTile` view with equal heights. The Outcomes tile reads "Outcomes / 50% good", so the value no longer wraps.
- At accessibility text sizes, the dashboard header, the Quick Stats tiles, the Recent Decisions header and the decision rows stack vertically, so no word breaks in the middle.
- At accessibility sizes the Overview grid is one column, the Outcomes legend sits under the ring, and the accuracy counts, the Optimism card and the detail screen's category, stakes and status stack.
- Chart text stops growing at the largest non-accessibility size, because axis labels cannot wrap. Outcome Trends labels every second week above the default size.
- At accessibility sizes the outcome picker shows one full-width row per outcome.
- Decorative header and empty-state icons are hidden from VoiceOver.
- The Save button in Revisit and Mark Outcome is pinned at the bottom. It stays above the keyboard and no longer sits at the screen edge when a follow-up is on.
- Rows in the Decisions list have a context menu with Edit and Delete. It replaces a hidden long-press gesture that went straight to the delete alert.
- `decisions.json` is written with sorted keys, so the same decisions always give the same file. Existing files load unchanged.
- The splash ("Welcome to Offshoots") shows on the first launch only, not for 2 seconds on every launch.
- Settings > We Also Make shows each app's real icon, with a light and a dark variant taken from that app's own icon set. The Task(ed) placeholder icon is gone. Muzzletoff is now listed as EveryPaw (same App Store ID).
- The top rating reads "Great", not "Very Good". Short labels are spelled out ("Very Bad", not "V. Bad").
- Settings > We Also Make lists AisleWise, Muzzletoff and Task(ed) only (April cleanup); five other apps are gone.
- Known: the placeholder in the decision title field is cut off at accessibility sizes. SwiftUI draws a placeholder on one line. The Stakes segmented control does not grow with the text (system control).

#### Fixed
- The detail screen now shows edits and outcomes at once. It no longer shows a stale copy.
- Tapping a reminder opens the Decisions tab and the right decision. This works for cold launch and repeat taps.
- The Settings "Follow-up Reminders" toggle now cancels reminders when off and reschedules them when on.
- An unreadable `decisions.json` is copied aside before the store can overwrite it.
- You can no longer choose a review date in the past.
- "See All" switches to the Decisions tab and no longer opens a second navigation stack.
- Completed rows show the date the outcome was marked (`resolvedAt`).
- Good %, the Outcomes chart and Outcome Trends now use the latest revisit rating.
- The trend and Outcome Trends group decisions by the date the outcome was marked, not the date the decision was logged.
- The trend shows "Too early" when there is too little data, instead of "Stable". It now compares 30-day windows.
- Top Category shows "Tied" on a tie, instead of a random pick.
- The Outcomes legend on Insights always adds up to 100%. It used to cut off the decimals, so it could show 97%.
- Empty Outcomes and Prediction Accuracy cards fill the width, like the other Insights cards.
- Editing a pending decision's title also updates its scheduled reminder, which shows the title.
- The Upcoming header and the Pending badge are readable in light mode.
- Deep Clay (Very Bad) is readable in dark mode (was 2.4:1 on Loam).
- Categories chart labels were black in dark mode, and kept their old color after a live switch between light and dark. The chart now rebuilds when the color scheme changes.
- Tied categories keep a stable order (by name). Before, they swapped places on each redraw.
- `AccentColor` had no value. The date picker selection uses the accent on iOS 26.5. On iOS 27.0 the system draws it in the label color.
- VoiceOver read the Good icon's checkmark as "Selected", so the outcome picker always sounded as if Good was chosen. The picker buttons now say the outcome, and only the chosen one is marked selected.
- The picker's tap area is the whole tile (about 60 × 68 pt), not only the icon and text.
- Rating icons read the outcome name, not the symbol name ("Favorite", "Close"). Rows read "Expected Bad, turned out Good". Revisit history reads "Bad to Good".
- In Revisit and Mark Outcome, a tap outside a control or the keyboard's Done button closes the keyboard.
- On Log and Edit, a tap outside a text field did not close the keyboard. In Edit, Done did nothing while the notes field was focused.
- Every card on the decision detail screen takes the full width.
- The first-launch splash showed an empty space instead of the app icon (`offshootsdar` was not an image set). It now uses a `splashicon` image set made from the dark app icon.
- In dark mode, Settings rows used the system grey instead of the Loam card color. The row color is now set on each section.
- The Delete All dialog reads "Delete 1 decision?" when one decision is left, not "Delete all 1 decisions?".
- A day in the graphical review-date calendar on Log and Edit could not be tapped. The month arrows and the preset chips still worked. The tap-outside-to-close-the-keyboard gesture on the form (Section 5) took the tap before the calendar got it. The gesture now runs only while a text field has focus, in LogDecisionView, EditDecisionView, MarkOutcomeView and RevisitView. Checked on the iPhone 17 (iOS 27) by Geoff.

#### Removed
- The Tip Jar screen, its StoreKit manager and the Support section in Settings. The four tip products are already Removed from Sale in App Store Connect.
- The StoreKit framework link. Nothing else in the app used StoreKit.
- The unused Decision Quality Score function and its README line.
- Unused `SectionHeader` view, and the unused `deletePending(at:)` and `deleteCompleted(at:)` helpers in the Decisions list.

#### Internal
- The app builds in Swift 6 language mode (`SWIFT_VERSION` 5.0 to 6.0). No code changes were needed.
- Decided: keep JSON storage and add no schema version yet (see DECISIONS).
- An `OffshootsTests` target (Swift Testing, iOS 18.6) with `AnalyticsEngine` tests built on the Insights fixtures, and a shared `Offshoots` scheme with a Test action.
- `DecisionStore(saveURL:)` and store tests for save-then-load and for the backup of an unreadable file. Store tests for the export and for Delete All (17 tests).
- All reminder scheduling goes through `DecisionStore`. `update()` reschedules a pending decision's reminder when its review date changes. Settings calls `store.setRemindersEnabled(_:)`. Views no longer call `ReminderManager`.
- `DecisionStore` is `@Observable` instead of `ObservableObject`. Views read it with `@Environment(DecisionStore.self)`. The store no longer imports Combine.
- Review readiness is measured against the store's stored `today`, which moves forward when the app becomes active. `Decision.isReadyForReview` is now `isReadyForReview(asOf:)`, and rows get the result as a parameter.
- The store is created once, in `OffshootsApp`. Owned by `ContentView`, it decoded the file a second time when the splash ended.
- The test target signs with the app's team, and store tests delete their temporary folders. `Fixture` has its own file. Tests load fixtures from the test bundle, not a Mac file path, so they also pass on a device.
- Outcome Trends chart data got a new random id on every redraw. Its id now comes from the week and the outcome group. The other-apps list in Settings uses the App Store ID as its id.
- Nine source files had the Xcode header comment two or three times. Each file keeps one header now. The DashboardView header read "DasbboardView".
- Moved four Insights cards out of `AnalyticsView.swift` into their own files (no behavior change). `OutcomePickerView` and `OutcomeButton` have their own file.
- Removed `xcschememanagement.plist` from git (per-user Xcode state; the file stays on disk).
- The Tip Jar became a native screen pushed from Settings on 2026-09-25 (carried over from commit `4655cdf` on the unmerged April branch), then was removed on 2026-09-26.
- `scripts/seed.sh` and Insights fixtures in `docs/fixtures/` for simulator checks.
- `scripts/screenshots.sh` sets up the iPhone 18 Pro Max for App Store captures: dark mode, 9:41, seeded data moved to today, no splash. The status bar shows a plain full battery, not a charging bolt. The shot notes in the script give the scroll position that worked for each shot.
- `docs/fixtures/screenshots.json` with `ScreenshotFixtureTests`, which pins every number the shots show. First full capture pass: 7 dark-mode shots in `ASC Screenshots/Offshoots/Captures/2026-09-26/`.
- `MARKETING_VERSION` 2.0.0, build 1 (was 1.0, build 3).
- Docs: added the README (2026-03-12) and `.gitignore` (2026-07-12); started CHANGELOG, DECISIONS and TODO; tracked `docs/` in git; drafted `ASC_LISTING.md` for the relaunch; replaced the blanket `*.md` ignore with a Task(ed)-style `.gitignore`; the README lists all source files and the current tech stack.

#### Verification
- Sections 1–2 testing gate: simulator checks 1–5 pass on iOS 27.0 (2026-09-24). Results are in `docs/2026-09-23-audit-bugfixes-and-core-loop.md`.
- Device check passed on the iPhone 17 Pro (iOS 27.2 Beta 2). A real reminder arrived the next day and a tap opened the decision (2026-09-25).
- VoiceOver pass on the iPhone 17 with VoiceOver on (2026-09-26).

### 1.0 (before this changelog, from git history)

_Build 3 uploaded 2026-01-04 from `0e29c15`. Released 2026-01-12._

- 2025-12: first build. Decision tracking, dashboard, analytics, notifications, botanical color theme.
- 2026-01: Swift Charts insights, settings, decision editing, 5-point outcome scale, stakes, reflection, secondary follow-up, tip jar with 4 consumable purchases.
