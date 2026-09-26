# Screenshot Pipeline — Design

Date: 2026-09-26
Status: Approved 2026-09-26

## Problem

The 2026-09-26 captures work as Screeny or Shareshot mockups, but they are not
App Store quality:

1. The status bar shows 07:21 / 07:50 and no signal bars.
2. The screens contradict each other. Trend says "Improving", but Outcome Trends
   says "No outcomes in the last 8 weeks". All history is in July, and the
   Activity chart shows one spike.
3. The first shot shows "0% good" and "0 of 6 marked" with one decision.
4. Text shows half hidden under the glass tab bar (Dashboard rows, the Log
   outcome labels, the Insights Categories card).
5. The Outcomes legend adds up to 97% (16 + 16 + 33 + 16 + 16). This is our code:
   `OutcomeDistributionCard` truncates with `Int(...)`.
6. The Optimism line ("1.2 steps better than the first result") is hard to read
   without context.

## Goals

- One command gives a clean, seeded, dark-mode app on the 6.9" simulator.
- The data is the same on every capture day, and every screen agrees with the others.
- A unit test pins the numbers each shot shows.
- Fix the two app problems that the shots make visible (#5, #6).

## Non-goals

- Captions, backgrounds and device frames. Geoff does the finishing in a separate
  process. This pipeline ends at clean raw captures.
- Light mode captures. Dark only.
- Localized captures and other device sizes. The 6.9" set scales down.
- Automated taps (XCUITest). Claude drives the taps with the simulator tool, or
  Geoff taps by hand, as in Task(ed) and AisleWise.
- Screenshot code in the app target. No `ScreenshotSeed`, no `-screenshots` argument.
- Changes to `scripts/seed.sh`.

## Shot list

App Store Connect allows 10. Seven shots, in this order:

| # | Name | Screen | Notes |
|---|---|---|---|
| 01 | `01-dashboard` | Dashboard | Top of screen. No row text half under the tab bar. |
| 02 | `02-log` | Log a Decision | Type a title and a note. Stakes High, prediction Good. Scroll until the outcome labels clear the tab bar. **Do not save.** |
| 03 | `03-detail` | Decision detail | The decision with the Bad → Neutral → Good timeline. |
| 04 | `04-revisit` | Revisit sheet | Open from 03. Pick a rating and type a note. **Do not save.** |
| 05 | `05-decisions` | Decisions list | Top of screen: Revisit, Upcoming, History. |
| 06 | `06-accuracy` | Insights | Accuracy and Optimism cards fully in view. |
| 07 | `07-patterns` | Insights | Categories and Outcomes cards fully in view. |

Saving on 02 or 04 schedules a reminder, which shows the notification prompt on
a fresh simulator. That is why both shots are open, fill, capture, cancel.

## Fixture

**File:** `docs/fixtures/screenshots.json`. It is an array of `Decision` in the
normal store format (ISO 8601 dates), anchored to **2026-09-27**. All times are
12:00 UTC, so a whole-day shift never crosses a day boundary.

The folder is a synced group in `OffshootsTests`, so the fixture is in the test
bundle. `AnalyticsEngineTests` already pins "now" to 2026-09-27.

About 15 decisions, all 6 categories, with plain, relatable titles.

| Need | For shot | Fixture content |
|---|---|---|
| A revisit due today | 01, 05 | One marked decision with `secondaryFollowUpDate` = anchor day |
| A timeline with history | 03 | One decision first rated Bad, revisited to Neutral, then to Good, each with a note |
| Future reviews | 05 | 2 pending decisions, due in the next 1–2 weeks |
| A 30-day Trend | 01 | At least 3 marked in the last 30 days and at least 3 in the 30 days before, with better accuracy recently, so Trend shows "Improving" (not "So far") |
| Outcome Trends | 07 | Marked decisions spread across the last 8 weeks |
| Whole percentages | 01, 06, 07 | 10 marked decisions. Latest ratings Very Bad 1, Bad 1, Neutral 2, Good 4, Great 2, which gives 10 / 10 / 20 / 40 / 20% and "60% good". Accuracy and Optimism are whole, believable values (for example 70% and "Optimistic, 0.5 steps"). |

Dashboard "Recent" shows the first 3 decisions in array order, so order the file
newest first. Check that the starter suggestions card is hidden at this count.

**Fixture test** (`OffshootsTests`): decode `screenshots.json`. With now =
2026-09-27, assert:

- Pending, completed and total counts
- Good %, top category, and Trend = Improving
- Accuracy %, and the correct, close and missed counts
- Optimism lean and step value
- Outcome percentages (10 / 10 / 20 / 40 / 20)
- The due revisit is ready for review, and the 2 pending decisions are not

If the weighted accuracy gives a different value from the target, change the
fixture, not the test target.

## Script

**File:** `scripts/screenshots.sh`, the Task(ed) and AisleWise pattern.

`setup` (the default):

1. Find the iPhone 18 Pro Max on iOS 27.0 by name (`DEVICE` and `OS` can be
   overridden). Shut it down, erase it, boot it, and open DeviceHub. Get its path
   from `xcode-select -p`, with a fallback to Simulator.app. Wait with `bootstatus`.
2. `simctl ui appearance dark`. `simctl status_bar override --time 9:41
   --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3`.
3. Build the `Offshoots` scheme into `build/screenshots-dd` for that UDID, then install it.
4. Move every date in the fixture by *today − 2026-09-27* in whole days, including
   the nested `revisits[].date`. A short inline `python3` step does this. Write the
   result to the app container as `Documents/decisions.json`.
5. `simctl spawn <UDID> defaults write com.geoffrey.silva.Offshoots hasSeenSplash -bool YES`,
   then launch the app.
6. Print the shot list with the notes above.

`shot <name>`: `simctl io <UDID> screenshot` to
`~/Documents/Dev Workstation/App Images/ASC Screenshots/Offshoots/Captures/<YYYY-MM-DD>/<name>.png`
(`SCREENSHOT_OUT_DIR` can override the path). The dated folder means a new run
never overwrites an older one.

Add `build/` to `.gitignore`.

## App fixes

**Outcome percentages.** Move the calculation from
`OutcomeDistributionCard.swift:60` into `AnalyticsEngine`. Use the largest
remainder method, so the shown percentages always add up to 100. Ties in the
remainder go in outcome order (Very Bad first), so the result is stable. Tests:
the 2026-09-26 counts (1, 1, 2, 1, 1) give 17 / 17 / 33 / 17 / 16, an even split
works, and an empty input returns no rows.

**Optimism copy.** In `OptimismCard`:

- Better: "On average, you expect {n} steps better than the outcome you first
  mark, across {count} decisions."
- Worse: "On average, you expect {n} steps worse than the outcome you first
  mark, across {count} decisions."

Update any test that checks the old text.

## Build order

Branch `screenshot-pipeline`. Each chunk is a separate stop that Geoff reviews.

1. **App fixes** with tests. Check: `scripts/seed.sh insights-seed`, then open
   Insights. The Outcomes legend adds up to 100, and the new Optimism line shows.
2. **Fixture, fixture test, `screenshots.sh`, `.gitignore`.** Check: run
   `scripts/screenshots.sh` and look at the seeded app on the 18 Pro Max.
3. **One full capture pass** and Claude's review of every image: the 6.9"
   App Store size (1320 × 2868 on the 17 Pro Max; confirm the 18 Pro Max on the
   first shot), 9:41, dark, no text cut off or half hidden, no alerts, numbers match the
   fixture test. Check: open the dated Captures folder.

## Docs

- CLAUDE.md: a short Screenshots section with the command, the fixture anchor,
  the "do not save on 02 and 04" rule, and the output folder.
- DECISIONS: JSON fixture over `ScreenshotSeed`; dark only; the 7-shot list;
  raw captures only (finishing is a separate process); largest remainder
  percentages; the Optimism wording.
- CHANGELOG and TODO as usual.
