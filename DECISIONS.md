# Decisions

Newest last. Format: `## YYYY-MM-DD (title)`, then **Decision** / **Why** / **Alternative considered**.

## 2026-09-23 (Revisits keep history and can be chained)
**Decision:** A marked decision can be re-rated any number of times. Each revisit stores a date, a rating and an optional note. The first marked outcome stays in `actual` and is the basis for prediction accuracy. The latest revisit (`currentOutcome`) drives the hero, the badge and the list rows.
**Why:** Outcomes change over time. Keeping the history shows how a decision aged, and accuracy stays fair because it measures the prediction against the first result.
**Alternative considered:** Overwrite the outcome on each revisit. This loses the history and makes accuracy drift.

## 2026-09-23 (Ask for notification permission in context)
**Decision:** Do not ask at launch. Ask the first time the app schedules a reminder, including when the Settings toggle is turned on and pending reminders are rescheduled.
**Why:** The user sees why the app wants permission, at the moment it matters.
**Alternative considered:** Ask at launch. This was removed.

## 2026-09-24 (Point Zero for project docs)
**Decision:** Start CHANGELOG, DECISIONS and TODO today. Backfill only from git history and the 2026-09-23 audit doc. Do not try to rebuild older decisions.
**Why:** The history is 17 commits and the audit doc already records all recent work. A deeper dig would guess at reasons that were never written down.
**Alternative considered:** A full reconstruction from old commits.

## 2026-09-24 (Track docs/ in git)
**Decision:** `.gitignore` ignores `*.md` but makes an exception for `docs/**/*.md`.
**Why:** Plans, specs and session notes must live in git with their history.
**Alternative considered:** Force-add single files. That is easy to forget and hides new docs.

## 2026-09-25 (Outcome stats use the latest rating; accuracy uses the first)
**Decision:** Good %, the Outcomes chart and Outcome Trends use `currentOutcome` (the latest revisit, else the first rating). Prediction accuracy, the quality trend and optimism bias use `actual` (the first rating).
**Why:** This applies the 2026-09-23 revisit rule to Insights. Outcome stats describe how decisions turned out. Accuracy measures the prediction against the first result.
**Alternative considered:** Use the first rating everywhere. Then a revisit never changes Insights, and the Dashboard hero and Insights disagree.

## 2026-09-25 (Insights time windows use the resolved date)
**Decision:** Trend windows and Outcome Trends group decisions by `resolvedDate`: `resolvedAt`, else `followUpDate` for rows resolved before `resolvedAt` existed. Decision Activity still uses `createdAt`.
**Why:** An outcome belongs to the week it was marked, not the week the decision was logged. Activity is about logging, so `createdAt` is right there.
**Alternative considered:** Keep `createdAt`. Most outcomes then fall outside the recent windows, so the trend almost never has data.

## 2026-09-25 (Trend compares 30-day windows and can say "Too early")
**Decision:** The trend compares accuracy in the last 30 days with the 30 days before. Each window needs 3 marked decisions, otherwise the tile shows "Too early". The trend is a typed `QualityTrend`, not a string.
**Why:** Review dates are often weeks away, so 7-day windows were nearly always empty and showed a false "Stable".
**Alternative considered:** Keep 7-day windows. Rejected for the reason above.

## 2026-09-25 (Top Category shows "Tied")
**Decision:** When two or more categories share the top count, the tile shows "Tied".
**Why:** The old code picked from dictionary order, so the tile could change between launches.
**Alternative considered:** A fixed tie-break order. It is stable, but it states a winner that does not exist.

## 2026-09-25 (Accuracy shows near misses apart; the headline stays exact)
**Decision:** The accuracy donut has three parts: Correct (exact match), Close (one step off) and Missed (two or more). The percentage counts exact matches only.
**Why:** On a 5-point scale, exact-only makes a Good/Great miss look the same as a Great/Very Bad miss. The headline stays strict so it does not rise just because the scale is wide.
**Alternative considered:** Count one step off as accurate. It inflates the number and changes what "Accuracy" means.

## 2026-09-25 (Optimism bias card)
**Decision:** Insights shows the average of expected minus first rating, in steps. At a quarter step or more either way it says Optimistic or Pessimistic, otherwise Well calibrated. It needs 3 marked decisions.
**Why:** The README promises to show where you are optimistic. This is the simplest measure of that, and it uses `numericValue`.
**Alternative considered:** Optimism per category. It needs more data per category than most users will have. Revisit later.

## 2026-09-25 (Remove decisionQualityScore; stakes weights stay unused)
**Decision:** Remove `AnalyticsEngine.decisionQualityScore()` and its README line. Leave `DecisionStakes.weight` in place but unused.
**Why:** The score was never shown, and the Accuracy tile and the 30-day trend already cover it. A stakes-weighted accuracy is a feature nobody asked for, so it waits for a real need.
**Alternative considered:** Show the score as another tile. It would repeat Accuracy with a different window.

## 2026-09-25 (Keep JSON storage; no schema version yet)
**Decision:** Keep `decisions.json` as the store. Do not move to SwiftData. Do not add a schema version wrapper until a model change needs one that the tolerant decoder cannot handle. The wrapper must still read plain arrays.
**Why:** The data is one small flat array. The decoder already handles new fields with defaults, and the store backs up a file it cannot read. `scripts/seed.sh`, the fixtures and the simulator steps all depend on the JSON file. CloudKit sync is not on the roadmap, and that is the main thing SwiftData would give.
**Alternative considered:** SwiftData. It adds migration risk and breaks the seed workflow for no user-facing gain. Reconsider if sync is planned.

## 2026-09-25 (Review readiness uses the store's stored day)
**Decision:** `DecisionStore` keeps a stored `today`. `refreshReviewState()` sets it when the app becomes active. Readiness is `isReadyForReview(asOf:)`, and callers pass `store.today`. Rows take the result as a parameter.
**Why:** `@Observable` tracks stored properties, not `Date()`. The old `objectWillChange.send()` trick does not exist on `@Observable`. A stored value makes the dependency visible, and rows redraw when it changes.
**Alternative considered:** A timer that ticks at midnight. It adds work for a case the foreground refresh already covers well enough.

## 2026-09-25 (Section 5 UI decisions)
**Decision:** The accent is an adaptive asset: a darker olive in light mode for contrast, Matcha `#A4C639` in dark mode. Dark mode uses the Soil and Loam colors for background and cards; light mode uses system colors. Category chart bars all use the accent. Rows get a context menu (Edit, Delete) in place of the hidden long press. Settings gets JSON export through `ShareLink` and Delete All with confirmation. "App Theme" becomes a System/Light/Dark picker; the "App Icon" row goes. The splash shows on first launch only. Revisit-due rows get a "Revisit" pill.
**Why:** Matcha text is about 2:1 on white (fails WCAG AA). Outcome colors already mean good and bad, so they should not also mean categories. Swipe actions outside `List` need iOS 27, and the app targets iOS 18.6. Every row in the Ready section should have the same shape.
**Alternative considered:** Delete the unused dark palette; keep a shorter splash on every launch; keep revisit rows without a pill.

## 2026-09-26 (Review-date presets, no same-day option)
**Decision:** Log and Edit Decision get four presets: Tomorrow, 3 days, 1 week and 1 month. A preset adds whole days to now and keeps the time of day. There is no "Tonight" preset.
**Why:** Short reviews build a new user's sample fast. Readiness is day-based (`isReadyForReview` uses the start of the review day), so a same-day review would be ready as soon as it is saved. Keeping the time of day keeps reminder timing as it was.
**Alternative considered:** A "Tonight" preset with a time-of-day readiness rule. It touches readiness, Ready to Review and reminders for a small gain.

## 2026-09-26 (Trend "So far" from the user's own history)
**Decision:** When the 30-day windows do not both have 3 marked decisions, but the user has 6 or more, the trend compares the older half of the marked decisions with the newer half, sorted by resolved date. With an odd count, the newer half gets the extra one. The Dashboard tile reads "Trend · So far". `qualityTrend` returns a `TrendResult` with an `isSoFar` flag, not a new `QualityTrend` case.
**Why:** The 30-day rule cannot show a trend before about day 31, however active the user is. With the review presets, an active user can reach 6 marked decisions in a week or two.
**Alternative considered:** An "Early read" at 2 per 30-day window (still about day 31), or a lower minimum with no label (the false signal the 2026-09-25 decision rejected). Accepted limit: at 6 decisions each half's accuracy moves in steps of a third, so Stable needs an exact match. The "So far" label covers this until the 30-day windows fill.

## 2026-09-26 (Starter suggestions until 5 decisions)
**Decision:** While the user has logged fewer than 5 decisions, the Dashboard shows three small example decisions, one per category, from a fixed list of six. A logged example drops out by title. A tap pre-fills the Log form through a value that `ContentView` owns. There is no dismiss control.
**Why:** A new user's first weeks are mostly waiting. Small decisions with a review tomorrow build the sample that Insights need, and show what a decision can look like.
**Alternative considered:** Suggestions on the empty Decisions list too, or a dismiss control. Both add surface for a card that goes away by itself.

## 2026-09-26 (Result line and progress copy)
**Decision:** Every marked decision shows a result line on Decision Detail, measured against the first rating (exact, one step better or worse, or more). While fewer than 6 decisions are marked, a second line says what unlocks next. The trend tile shows "N of 6 marked" in place of "Too early", and empty Insights cards say "Mark your first outcome to see this."
**Why:** The first marked outcome gave nothing back unless the guess was exact, and "Too early" did not say what to do. The first rating is the same basis that accuracy uses.
**Alternative considered:** A short overlay after Save in Mark Outcome. It disappears, and VoiceOver users can miss it.

## 2026-09-26 (Outcome percentages use the largest remainder)
**Decision:** The Outcomes legend rounds with the largest remainder method, so the shown percentages always add up to 100. Ties go in outcome order, Very Bad first. The calculation lives in `AnalyticsEngine.outcomeDistribution(from:)`.
**Why:** The legend truncated, so 6 decisions showed 16 + 16 + 33 + 16 + 16 = 97%. A legend that does not add up to 100 looks broken, in the app and in App Store screenshots.
**Alternative considered:** Plain `.rounded()`, as the rest of the app does. Simpler, but the same data shows 101%.

## 2026-09-26 (Optimism wording)
**Decision:** "On average, you expect {n} steps better (or worse) than the outcome you first mark, across {count} decisions." The calibrated line uses the same "outcome you first mark".
**Why:** "Than the first result" did not make sense without context, for example in an App Store screenshot. The new line still says that the bias is measured against the first rating.
**Alternative considered:** "You tend to expect better than you get: 1.2 steps on average." Easier to read, but it drops the first-rating detail.

## 2026-09-26 (Screenshot pipeline: raw captures from a date-shifted JSON fixture)
**Decision:** `scripts/screenshots.sh` loads `docs/fixtures/screenshots.json`, anchored to 2026-09-27 and moved to the capture day. Dark mode only, 7 shots (Dashboard, Log, Detail, Revisit, Decisions, Insights accuracy, Insights patterns), raw captures only. Captions and frames happen in a separate finishing process.
**Why:** It extends the `seed.sh` method this repo already has and ships no screenshot code in the app. The date shift keeps trend windows, due revisits and charts the same on any capture day. A test pins the numbers.
**Alternative considered:** A Swift `ScreenshotSeed` behind a `-screenshots` argument, as in Task(ed) and AisleWise. It works, but it ships fixture code in the app binary.

## 2026-09-26 (Screenshot capture details)
**Decision:** The status bar uses `--batteryState discharging --batteryLevel 100`. Shot 03 (Decision detail) is framed at the bottom of the page: the result line, Reflection, the revisit timeline and the Revisit Decision button. Shot 05 (Decisions list) is scrolled about 90 pt, with the large title collapsed. The scroll notes are in `scripts/screenshots.sh`.
**Why:** On iOS 27.0, `charged` draws a green battery with a charging bolt. On Detail, the Actual Outcome header and the page end do not both fit clear of the navigation bar and the tab bar. On the list, a History row sat half under the tab bar at the top, and the large title only stays fully open or fully collapsed.
**Alternative considered:** `--batteryState charged`, as the spec said. Shot 03 at the Actual Outcome card and shot 05 at the top of the list, as the spec said: both left text half hidden.

## 2026-09-26 (Tip Jar removed for the 2.0.0 relaunch)
**Decision:** The Tip Jar is removed from the app: both Swift files, the Settings "Support" section and the StoreKit link. The listing and README no longer mention it.
**Why:** The four tip products are Removed from Sale in App Store Connect, so the screen could only show "Tip Jar Unavailable". Tips were consumables that unlocked nothing, so no entitlement or restore path is lost.
**Alternative considered:** Keep the screen and re-list the products. It keeps a small income stream, but it adds an in-app purchase to review for the relaunch.

## 2026-09-26 (Gate the tap-to-close-keyboard gesture on focus)
**Decision:** The tap-outside-to-close-the-keyboard gesture on Log, Edit, Mark Outcome and Revisit runs only while a text field has focus (`including: <any field focused> ? .all : .subviews`). With no field focused, the gesture does not claim taps, so the calendar day underneath receives them.
**Why:** The gesture, added in Section 5, sat on the whole form and took every tap before the graphical calendar could select a day. Removing the gesture would drop the Section 5 tap-outside behavior.
**Alternative considered:** Remove the gesture. Rejected because it would bring back the keyboard staying open on an outside tap. Trade-off accepted: with the keyboard up, the first tap on a day closes the keyboard, and a second tap selects the day.

## 2026-09-26 (Task(ed)-style .gitignore replaces the docs exception)
**Decision:** `.gitignore` no longer ignores `*.md`. It ignores only Xcode user state, build output, AI tooling folders, PDFs and OS files. This replaces the 2026-09-24 "Track docs/ in git" rule.
**Why:** The blanket ignore needed an exception for each new root doc (ASC_LISTING, RELEASE_NOTES), and a missed exception hides a file from git without warning. The sibling apps already use this shorter file.
**Alternative considered:** Keep `*.md` ignored and add an exception per file. Easy to forget.

## 2026-09-26 (2.0.0 baseline and release notes)
**Decision:** Version 2.0.0 is every commit after `0e29c15` (2026-01-04). 1.0 (build 3) was uploaded from that commit on 2026-01-04 and released on 2026-01-12 (dates from Geoff). The April Settings cleanup and the July `.gitignore` commit came after the upload, so they belong to 2.0.0. No `v1.0` tag is added. Release notes live in `RELEASE_NOTES.md`, which starts with 2.0.0, and each release gets an annotated `v<version>` tag from here on.
**Why:** The upload date pins the 1.0 build to `0e29c15`, the last commit on or before it. The file name matches Task(ed), List-Happens, Muzzletoff and Weather-in-Words.
**Alternative considered:** A backdated `v1.0` tag on `0e29c15`. Geoff declined it: the `v2.0.0` tag already gives the next release pass its baseline. An earlier draft of this entry used `8ed7dac` (2026-07-12) as the baseline; that was a guess made before the upload date was known.
