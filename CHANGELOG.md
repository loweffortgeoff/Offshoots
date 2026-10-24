# Changelog

Release scope and development history. A prepared RC entry below does not establish public availability.

## In Progress

- 2026-10-24: The Hindsight purchase sheet follows Geoff's layout: centered headline, app mark, labeled example, and the one-time unlock button. The feature list and Apple Intelligence sentence are no longer on that sheet.

- 2026-10-24: Geoff set the paid package name to Hindsight and the United States price to $5.99 on the existing non-consumable. Both local StoreKit files now use that name and describe recording what you would repeat or change. App Store Connect remains Prepare for Submission. Paywall sentences and activation stay open.

- 2026-10-24: Fixed the independent-review Restore defect: latest verification uncertainty no longer claims purchase absence after an earlier clean check. Parameterized regression, 255 regular tests, local StoreKit, and Release build pass; repaired two preview environments and restored simulator files.

- 2026-10-24: Implemented optional Hindsight answers in reviews/revisits, dated history, and calculated answer/outcome filtering. 255 regular tests pass (ten opt-in skips), plus local StoreKit ownership/Restore/refund and simulator flows. Fixed largest-text filtering and Restore uncertainty; independent review fixes pass and production stays disabled pending acceptance.

- 2026-10-24: Geoff approved the full Hindsight design. Wrote the five-task implementation plan with backward-compatible answers, offline ownership, existing review/history integration, and calculated comparisons; execution awaits plan approval.

- 2026-10-24: Drafted Hindsight after Geoff approved the direction: optional same/different approach or choice check-ins, dated history, and calculated review across decisions. Full design and implementation await approval; generated Reflection is outside the proposed paid promise.

- 2026-10-24: Added a test-only PCC comparison at moderate reasoning. All 36 cases captured; quality still fails at 7/17 useful core readings (local baseline 6/17). Regular tests and Release build pass; production Reflection remains disabled.

Hindsight is the approved 2.1.0 paid direction after local and PCC quality failures; its implementation plan awaits approval. The prior generated-Reflection implementation and evaluation remain tracked; production paid Reflection remains disabled.

- 2026-10-24: Recorded PCC as the next comparative evaluation for paid readings. Geoff reports the branch pushed; `dev/paid-reflection` remains open work while he returns to `main` for website work.

- 2026-10-24: Fixed independent-review findings and passed 238 automated checks, local StoreKit transaction/Restore/refund, Release build, and final simulator UI checks. Scored model quality fails at 6/17 eligible core cases; paid activation remains blocked.

- 2026-10-24: Implemented evidence-linked readings, dated local history, source-change labels, manual refresh, failure recovery, and full backup/restore. Added 36 synthetic evaluation cases; physical-device quality and real-note acceptance remain open.

- 2026-10-24: Recorded spec approval and wrote the implementation plan. Sequenced evaluation, evidence, saved history, recovery, backup, cleanup, purchase, and device acceptance; production activation remains gated.

- 2026-10-24: Drafted the paid Reflection design: evidence-linked Patterns across categories, decision history readings, manual generation, and saved dated readings. Recorded the reversal of unsaved output and retained the existing quality gate.

- 2026-10-21: Groomed the 2.1.0 Reflection roadmap into six ordered tasks. Moved the Optimism fix outside RC scope and mapped release, feature, bug, and testing work to undated Things tasks.

## Shipped

### 2.0.0 — It Keeps Going After You Decide

**Live, as reported by Geoff on 2026-10-24.** Build 10 was the accepted RC. The exact public release time was not checked in this documentation session.

The first public baseline is the 1.0 upload, `0e29c15` (2026-01-04). Existing tag `v2.0.0` marks the earlier 2026-09-26 docs pass at `86a379e`; preserve it. This pass consolidates the later 152 commits into the same 2.0 scope. Use `v2.0.0-rc.10` for a reviewed RC docs handoff; do not move the old tag.

#### Added
- Free Look Back on Log: immediate counts, Expected/Turned out bars and Copy from two marked decisions in the category. It compares every prediction with its first outcome; the calculated headline needs five decisions and a clear lean.
- iPhone Duo: content and navigation stay clear of the fold. Dashboard, Log, Decisions and Insights use paired panes in wide landscape and partly open portrait; Settings stays in one pane.
- iPhone Duo: Dashboard pairs the review list with a selected decision. With no selection it shows the first decision ready for review, else the most recent, and keeps that decision after an outcome is marked.
- iPhone Duo: Decisions pairs its list and details. Log pairs the form with up to ten recent decisions; tapping one opens its details in Decisions.
- iPhone Duo: Insights pairs outcome/activity cards with trends, prediction accuracy and optimism. Fully open portrait keeps a readable centered column; other iPhones keep their existing layout.
- Settings > Data > Import Decisions restores an Export Decisions file. An empty app imports at once. Otherwise it asks "Replace N decisions with M from the file?" first. A wrong file shows "This file is not an Offshoots export." Old reminders are cancelled and the imported decisions' future reminders are scheduled.
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
- VoiceOver on Insights: each chart reads as one short summary instead of mark by mark. Decision Activity gives the 30-day total and the most in one day. Categories names the top category (or the tie) and each count. Outcomes reads each share ("Good 40%"). Outcome Trends gives the 8-week positive, neutral and negative totals. The Prediction Accuracy ring reads "70% accurate". The Overview tiles and the Correct, Close and Missed counts each read as one item ("Total: 12", "Correct, 7"). Build 8.
- Splash: the splash now shows on the first cold launch of each day, not only once after install. Later cold launches that day and returns from the background go straight to the Dashboard. The launch screen is the app background again (no green), and the splash green fades in with the icon and title. Before, every launch after the first showed about a second of plain green with no logo. Build 8.
- Offshoots builds only with Xcode 27.1 or later, because the fold APIs are in the iOS 27.1 SDK. The app still supports iOS 18.6 at runtime.
- The Decisions navigation path is now a list of decisions (`[Decision]`) instead of `NavigationPath`.
- iPad: the app window now resizes freely, up to the phone width that iPadOS allows (about 512 pt). Before, it snapped between two fixed sizes. The app stays iPhone-only. The deprecated `UIRequiresFullScreen` flag is removed.
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
- The splash ("Welcome to Offshoots") appears on the first cold launch each day; later opens and background returns go straight to the app.
- Settings > We Also Make shows each app's real icon, with a light and a dark variant taken from that app's own icon set. The Task(ed) placeholder icon is gone. Muzzletoff is now listed as EveryPaw (same App Store ID).
- The top rating reads "Great", not "Very Good". Short labels are spelled out ("Very Bad", not "V. Bad").
- Settings > We Also Make lists AisleWise, Muzzletoff and Task(ed) only (April cleanup); five other apps are gone.

#### Fixed
- Import reports an unreadable file clearly.
- iPhone Duo: in two-pane landscape the left pane (Decisions list, and the new Dashboard, Log and Insights panes) no longer stops 84 pt short of the split. Its `NavigationStack` kept the tab rail's inset clear although the rail sits beside the right pane. `WidePanes` reads the inset outside the split and widens the left pane by that much.
- Decision detail: the outcome badge no longer breaks into "Neu-tral" in a narrow detail pane (partly open Duo). The row fitted, but the HStack squeezed the badge; the badge now keeps its natural width, and the row stacks when it really does not fit.
- Log: a Log tab left open past midnight no longer keeps the old "tomorrow" as the review date. When the app comes back to the foreground on a new day, a review date that is no longer in the future moves to the new tomorrow. A date you picked that is still in the future stays.
- Outcome Trends: week labels that would touch their neighbour are now dropped, so "Aug 23" and "Aug 30" no longer read as one word on wide layouts such as the iPhone Duo. The iPhone 18 Pro now shows every second label at the default text size.
- Log and Edit Decision: the title prompt has room to wrap at accessibility text sizes. Stakes uses full-width choices with scaled text and a selected state at those sizes; standard sizes keep the segmented control. Geoff verified the fix on 2026-10-04.
- The header meta row on Decision Detail stacks from the xxLarge text size up. At larger sizes the "Neutral" rating wrapped as "Neu-tral".
- At accessibility text sizes, the revisit rows on Decision Detail broke the rating ("Good") and the date into one-letter columns. Each row now stacks the icons, the rating and the date at accessibility sizes, and keeps the side-by-side layout at other sizes. `RevisitHistoryCard` has its own file.
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
- The old Tip Jar StoreKit manager. StoreKit remains in the dormant Reflection implementation; no purchase setup runs in 2.0.
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
- `MARKETING_VERSION` 2.0.0, RC build 10. The previous public 1.0 upload was build 3.
- Docs: added the README (2026-03-12) and `.gitignore` (2026-07-12); started CHANGELOG, DECISIONS and TODO; tracked `docs/` in git; drafted `ASC_LISTING.md` for the relaunch; replaced the blanket `*.md` ignore with a Task(ed)-style `.gitignore`; the README lists all source files and the current tech stack.

#### Verification
- Sections 1–2 testing gate: simulator checks 1–5 pass on iOS 27.0 (2026-09-24). Results are in `docs/2026-09-23-audit-bugfixes-and-core-loop.md`.
- Device check passed on the iPhone 17 Pro (iOS 27.2 Beta 2). A real reminder arrived the next day and a tap opened the decision (2026-09-25).
- VoiceOver pass on the iPhone 17 with VoiceOver on (2026-09-26).
- Build 10: 202 tests in 24 suites pass on iPhone 18 Pro (iOS 27.0), with a Release simulator build on Xcode 27.1. Geoff accepted the build on his phone on 2026-10-17.
- RC tag `v2.0.0-rc.10` and local/remote main match `62ad837` (2026-10-17). Build 10 archived/uploaded with Xcode 27.1, processed Valid, and is attached to the 2.0.0 draft. Internal Low Effort is testing; test instructions and approved listing copy were saved and read back.
- Reflection remains a draft outside the 2.0 review setup. ASC remains Prepare for Submission with manual release; App Review and restoring App Store availability remain open. The latest read reports internal/external TestFlight testing; this screenshot pass submitted no review.
- Three approved Release build 10 screenshot replacements (Duo 3/4, iPhone Log) were promoted and uploaded to ASC 2.0.0 en-US. All are Complete with matching checksums/dimensions and original positions. Old local files are archived in `Sunset/2026-10-17-rc10-replaced/`; other images are preserved.
- Seven approved standard iPhone images now use upright phones, existing captions and no vines or detached UI. Promoted and uploaded to ASC 2.0.0 en-US; all Complete with matching checksums, 1290 × 2796 dimensions and original order. Old files are in `Sunset/2026-10-17-iphone-flat-replaced/iPhone/`; local and remote Duo sets are unchanged.

### 1.0 (before this changelog, from git history)

_Build 3 uploaded 2026-01-04 from `0e29c15`. Released 2026-01-12._

- 2025-12: first build. Decision tracking, dashboard, analytics, notifications, botanical color theme.
- 2026-01: Swift Charts insights, settings, decision editing, 5-point outcome scale, stakes, reflection, secondary follow-up, tip jar with 4 consumable purchases.

## Deferred implementation history — November 2.1.0

The following work reached development/TestFlight builds but is disabled in the 2.0 RC. It is not part of the 2.0 purchase or feature promise.

- Reflection, an optional $5.99 one-time unlock with Restore in Settings. Patterns on Insights, a reflection on Decision Detail, and Clean Up Note on the Log, Mark Outcome and Revisit note fields. The text comes from the on-device model, so nothing leaves the phone. It needs Apple Intelligence on iOS 26 or later; other devices do not see Reflection.
- Reflection: Look Back on the Log screen, between Stakes and Expected Outcome. It counts how your marked decisions in the chosen category went against their predictions, shows Expected and Turned out as two bars, and gives one labeled sentence per result group from the notes of the 5 newest. From 5 decisions, a clear lean adds a headline such as "Your Money decisions tend to fall short of your predictions". It needs 2 marked decisions in the category; below that it says how many to go.
- Reflection: the purchase sheet follows concept A ("Show the output"). It opens with the headline "See what your decisions add up to.", then a fixed Example card ("Your Work decisions tend to beat your predictions", the wording Look Back uses) with Expected and Turned out bars, then the "Reflection adds" list. The buy button reads "Unlock Reflection • <price>" over the line "One-time purchase. Logging and reviewing stay free.", and Restore Purchase is a text button. The navigation title is "Reflection". The buttons still stay pinned at normal sizes and scroll at accessibility sizes. Purchase logic is unchanged. Build 7.
- Reflection: Patterns now compares your notes, grouped by result (worse than predicted, as predicted, better). It writes one sentence per group under a fixed label (Went worse, Went as predicted, Went better) and no longer repeats the Insights numbers. Below 2 notes it says to add a note.
- Reflection: the decision reflection now looks at up to 5 other decisions in the same category. A new "In other <Category> decisions" section says what this decision shares with the ones that went the same way.
- Reflection: the "Unlock Reflection" sheet lists Patterns, the decision reflection and Look Back. Clean Up Note stays in the app but leaves the list.
- Reflection: the purchase sheet no longer says "not charged" when the purchase is unverified. The paywall keeps its pending state and clears the old Restore message. A control that is not ready says "Reopen the app in a little while." The Settings footer now covers text generation only. The Import picker shows "unreadable" for a file it cannot read.
- Reflection: Restore Purchase is full width at accessibility text sizes.
- Reflection: the "Unlock Reflection" sheet has a new look. A leaf logo sits above a centered intro. The three features share one card with dividers and green symbols, with the footnote "Nothing appears until you tap for it." The buy and Restore Purchase buttons stay at the bottom. At accessibility text sizes they scroll with the content, so they do not cover the card. The price still comes from the App Store and stays inside the button. Purchase logic is unchanged.
- Reflection: Look Back hides a sentence that only repeats a decision title. The model on a phone can copy its input back ("[Medium] Reply to that email today, not Friday."); the card then shows the counts and bars without it. Build 8.
- Reflection: Look Back no longer writes a sentence for a result group whose decisions have no notes. With titles alone the model made one up (seen 2026-10-14 on a Work card, where the note-less "as predicted" decision got a sentence). Build 8.
- Reflection: Look Back no longer shows its own prompt text. With one decision in a group, the on-device model could copy the input line back word for word, so the card read "[Medium] Put off email Response. Notes: \"…\" Outcome note: \"…\"" (build 7). Each group sentence now loses a leading `[Low]`, `[Medium]` or `[High]` and the `Notes:` and `Outcome note:` labels with their quoted text (`ReflectionText.dropPromptLeftovers`). This hides the leak only; whether the sentences copy notes at all is still open. Build 8.
