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

## 2026-10-01 (Reflection cards are hidden at the call site)
**Decision:** `AnalyticsView` and `DecisionDetailView` decide whether to show a Reflection card. When the device cannot run the model, the card is not in the view tree at all.
**Why:** An unsupported device must never see Reflection. Removing the view also drops its in-memory result, so a stale result cannot come back after a hidden period.
**Alternative considered:** An `if` inside the card. The first version of the plan did this and showed a title with no body. A `Group`-wrapped `onChange` does not work, because `Group` hands its modifiers to its children.

## 2026-10-01 (Patterns prompt: one line per group, accuracy labeled)
**Decision:** The Patterns prompt lists one line per category and per stakes group, for example "Work: 3 marked, all 3 matched the prediction exactly". It labels the accuracy figures "all categories combined".
**Why:** With the old format, the real on-device model attached the global "one step off" count to Work and wrote a false observation.
**Alternative considered:** Change the instructions only. The model can still misread a shared total, so the data format carries the fix.

## 2026-10-01 (Empty "What is repeating" when nothing repeats)
**Decision:** The model leaves the "What is repeating" section empty when nothing repeats. Geoff approved this on 2026-10-01. It lands in chunk 4 of the Reflection plan.
**Why:** On a decision with only revisits and no notes, the model filled the section with lines that say nothing.
**Alternative considered:** Keep the section always filled. It looks complete, but it shows text with no content.
**Superseded 2026-10-01:** Code skips the section when a decision has no written text. See "What is repeating is skipped in code".

## 2026-10-01 (Testing Reflection on the simulator)
**Decision:** On the Mac mini, the iOS 27.0 simulator reports the on-device model as available and runs it. The `-ReflectionUnlockOnly` launch argument gives real output on the simulator. A launch with no flag shows the paywalled state: the title with an empty body until chunk 5, not a hidden card.
**Why:** The plan assumed that the simulator has no model. Checked on the Mac mini that it does, so the plan's test steps need this note.
**Alternative considered:** Test on a device only. This is slower. A device run stays the final check, because nobody has compared simulator and device output.
**Update 2026-10-01:** Chunk 5 shipped the paywall. A launch with no flag now shows a locked control, not an empty body. No `-ReflectionPaywall` flag exists.

## 2026-10-01 (What is repeating is skipped in code)
**Decision:** A decision with no log note, no outcome note and no revisit note uses `decisionInstructionsWithoutNotes` and a generated shape with no `repeating` field. Decisions with notes keep the full instructions. This replaces "Empty 'What is repeating' when nothing repeats".
**Why:** Prompt wording alone failed twice on the real model. First it wrote filler, then it invented themes.
**Alternative considered:** Tell the model in the prompt to leave the section empty. That was the earlier decision.

## 2026-10-01 (Guide text for "What is repeating")
**Decision:** The `@Guide` text for `repeating` is "Up to three plain observations about what repeats. Empty if nothing repeats".
**Why:** The earlier text gave advice-like lines ("Talk about the car's use and cost") for a decision with one log note. Only one input was tested, and greedy output moves with small wording changes, so re-test after any edit.
**Alternative considered:** Keep the STOP 3 wording from the plan.

## 2026-10-01 (Clean Up instructions name the edits)
**Decision:** The Clean Up instructions list the edits: spelling, capitals, punctuation, grammar and run-on sentences.
**Why:** With the plan's general wording, the real model returned a rough note unchanged.
**Alternative considered:** The plan's wording ("tidy this note"). It did nothing on the test note.

## 2026-10-01 (Clean Up row hidden at the call site)
**Decision:** The Clean Up row is hidden at the call site, like the Reflection cards. Its reset sits on an always-present `VStack`, and `Use` also resets it.
**Why:** A hidden view drops its state, so a stale suggestion cannot return. Modifiers on a view that is not always present do not fire.
**Alternative considered:** An `if` inside the row, with the reset on the row. It leaves the reset in a view that may not exist.

## 2026-10-01 (No -ReflectionPaywall launch flag)
**Decision:** No `-ReflectionPaywall` flag. A plain launch shows the locked state.
**Why:** The simulator runs the model, so a launch with no flag is already locked. A flag adds code for no new case.
**Alternative considered:** A flag that forces the locked state. It matters only on a device with no model.

## 2026-10-01 (Import Decisions asks only when data exists)
**Decision:** Settings > Data > Import Decisions imports at once into an empty store. When decisions exist, it asks "Replace N decisions with M from the file?" first. A wrong file shows "This file is not an Offshoots export." The import cancels old reminders and schedules the future reminders of the imported decisions.
**Why:** An import replaces data, so it needs a confirmation when something could be lost. An empty store loses nothing, and a confirmation would only slow a restore. This follows the rule that destructive actions are confirmed and others are not.
**Alternative considered:** Merge the file into the existing decisions. It needs duplicate rules, and an Export file is a full copy.

## 2026-10-01 (Test purchases only from an Xcode run)
**Decision:** Test Reflection purchases only from an Xcode run with `Reflection.storekit` on the scheme. Do not test with `simctl launch`.
**Why:** The StoreKit file applies only when Xcode runs the app. A `simctl launch` ignores it, so the product does not load.
**Alternative considered:** A debug purchase flag in the app. It would skip the code path that real purchases use.

**Update 2026-10-01:** This holds for the simulator only. On a physical phone, Xcode's StoreKit test mode fails with `ASDServerErrorDomain Code=2010`. See the next entry.

## 2026-10-01 (Test purchases on a phone in the sandbox)
**Decision:** Test Reflection purchases on a physical phone in the real App Store sandbox, not in Xcode's StoreKit test mode. Take `Reflection.storekit` off the Run action by hand for that run, sign in under Settings > Developer > Sandbox Apple Account, and run from Xcode. `Reflection.storekit` stays on the committed scheme for the simulator.
**Why:** On both phones (iOS 27.0 and 27.2 beta 2), the Xcode test mode returned `ASDServerErrorDomain Code=2010` on every purchase, with no transaction. The same build buys on the simulator. In the sandbox the same build bought on both phones, and the unlock stayed after a relaunch. Console logs showed the unlock code was correct: the earlier "unlock comes back" was the failed-purchase state, not a lost unlock. Apple does not document code 2010, so the cause is not known.
**Alternative considered:** Remove `Reflection.storekit` from the scheme for good. Then the simulator would need a sandbox account too, and simulator purchase, restore and refund checks would be lost.

## 2026-10-02 (Reflection is a paid one-time unlock)
**Decision:** Reflection is a one-time purchase at $5.99 (`com.geoffrey.silva.Offshoots.reflection`, non-consumable, Family Sharing off). The entitlement checks a list of product IDs, so a low-cost subscription can be added later with no rework. This overrides the Contrition "No subscriptions" guardrail. The paywall price comes from the App Store, never from a constant.
**Why:** The on-device model costs nothing to run, so there is no running cost to cover. A one-time price fits a utility app with no account. The ID list keeps the subscription option open.
**Alternative considered:** A subscription from the start. It adds renewal and cancellation states for a feature that has no server cost.

## 2026-10-02 (Reflection output is never saved; no free preview)
**Decision:** Reflection output is regenerated on demand and never stored. There is no free preview. Surfaces hide when the model does not support the language, so there is no localization work.
**Why:** Saving output adds a data model and a sync question. A free preview adds a gate state and a stored flag. Neither earns its cost in v1.
**Alternative considered:** Save the last output per decision; offer one free try.

## 2026-10-02 (Reflection thresholds and gate states)
**Decision:** Patterns needs 5 marked decisions. Clean Up Note needs at least 3 words and at most 1,500 characters. The gate has four states, and `notReady(reason:)` shows a disabled control with its reason.
**Why:** Fewer than 5 marked decisions gives the model too little to say. A disabled control with a reason tells the user what to do next, and a hidden control does not.
**Alternative considered:** Hide a control that is not ready. The user cannot learn what unlocks it.

## 2026-10-02 (The -ReflectionUnlockOnly merge trap is already closed)
**Decision:** On `reflection`, the shared scheme keeps `-ReflectionUnlockOnly` but disabled (`isEnabled = "NO"`), and it holds the `Reflection.storekit` reference. `main` is already merged into `reflection`, so the merge back is a fast-forward and the scheme lands as is. The `b792f1c` commit on `main` enabled the argument; after the merge, confirm it is disabled on `main`.
**Why:** The argument works only in DEBUG builds. If it stays enabled, every Xcode run starts unlocked and nobody can test the paywall.
**Alternative considered:** Delete the argument. It stays as a device-only shortcut for real-model checks.

## 2026-10-02 (No Clean Up Note in Edit Decision, v1)
**Decision:** The Notes field in Edit Decision has no Clean Up Note row in v1. Clean Up Note stays on the Log, Mark Outcome and Revisit note fields.
**Why:** Geoff confirmed this on 2026-10-02. It keeps v1 small, and the three fields where a note is first written already have the row.
**Alternative considered:** Add the row to Edit Decision for parity. It can come later if testers ask.

## 2026-10-02 (Patterns prompt stays as is until real data)
**Decision:** Do not change the Patterns prompt yet. On the uniform test data, the output was four near-identical "matched the prediction exactly" lines, and the groups overlapped (work was counted twice). The Clean Up Note meaning-change question also stays open.
**Why:** The test decisions were all alike and had no notes, so the output shows the data, not a prompt fault. A prompt change now would fit the test data and not real use.
**Alternative considered:** Rewrite the prompt to merge overlapping groups now. Re-check with varied real decisions and notes first.

## 2026-10-02 (Unlock Reflection sheet: pinned buttons, price in the button, feature copy kept)
**Decision:** The buy and Restore Purchase buttons are pinned to the bottom of the sheet with `safeAreaInset`. At accessibility text sizes they scroll with the content instead. The price stays inside the buy button text and comes from `displayPrice`. The three feature titles keep their current copy, even though the Claude Design concept had longer descriptions.
**Why:** Pinned buttons keep the purchase action in reach at normal sizes. At AX3 the pinned buttons covered the feature card, so they scroll there. Geoff chose to keep the price in the button, so the price and the action stay in one place. Geoff chose to keep the titles (option a): the card stays short, and no new copy needs a check.
**Alternative considered:** Pin the buttons at every size (covers the card at AX3). Show the price as a separate line (more layout, less clear). Use the longer descriptions from the Claude Design concept (a taller card, and new copy to check).

## 2026-10-03 (Stay iPhone-only on iPad)
**Decision:** Offshoots stays iPhone-only (`TARGETED_DEVICE_FAMILY = 1`). On the iPad it runs as an iPhone app in a window. `UIRequiresFullScreen` is removed, so that window resizes freely up to the iPadOS limit for iPhone apps (about 512 pt wide).
**Why:** Full iPad support adds a second device family: iPad screenshots every release, an iPad layout pass, and more risk at App Review. Removing the flag costs nothing. The flag is deprecated since iPadOS 26, and with it iPadOS 27 snaps the window between fixed sizes (about 375 and 512 pt). Checked on the iPad Pro 13-inch (M5) simulator, iOS 27.0, on the Mac mini.
**Alternative considered:** Add iPad to the device family, with a content width cap. This was rejected: it doubles the overhead and the review risk.
