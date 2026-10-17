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

## 2026-10-04 (Decision form controls at accessibility sizes)
**Decision:** Give the native title field at least three lines at accessibility sizes. Use shared full-width Stakes buttons there, with scaled body text and a selected trait. Keep the system segmented control at standard sizes.
**Why:** Simulator testing confirmed the title prompt truncates and the segment labels stay small. This repairs Log and Edit without changing the stored values.
**Alternative considered:** A custom title placeholder. The native field already supports a multiline prompt when it has enough lines.

**Verification (2026-10-04):** Geoff confirmed the fix is verified and approved merge, commit and push.

## 2026-10-07 (Offshoots does the iPhone Duo properly before the GM)
**Decision:** Offshoots gets a full fold-aware layout (`ReservedRegion` `.division`, `ArrangementView` `.split`) before its GM, which comes after the Duo ships. Other apps (Task(ed), Aislewise and the rest) may start with a "not broken" pass. "Buttons down" on the closed Duo is an Apple bug, not ours, so we do not work around it. Findings: `docs/2026-10-07-iphone-duo-findings.md`.
**Why:** Offshoots is not released yet, so the right layout costs no more now than later. Apple's own apps also draw wrong when the closed Duo is held buttons down, and no Duo API controls that.
**Alternative considered:** A minimum fix that only pads content away from the fold. Rejected for Offshoots; it is still an option for the other apps.

## 2026-10-07 (Offshoots builds only with Xcode 27.1 or later)
**Decision:** Offshoots builds only with Xcode 27.1 or later, and only on the Mac mini. The fold APIs (`.division` reserved region, `GeometryProxy.reservedRegions`) are in the iOS 27.1 SDK. The app still supports iOS 18.6 at runtime: the fold code sits behind `#available`. Other projects stay on regular Xcode. Offshoots does not release before the Duo does.
**Why:** The fold layout needs these APIs. The Mac mini is the only machine that moves to Xcode 27.1 for now, and no other project needs the new SDK. The release waits for the Duo anyway.
**Alternative considered:** Move every project and both Macs to Xcode 27.1. Rejected: it risks other apps for no gain.

## 2026-10-07 (Fold layout: refinements to the spec)
**Decision:** Four refinements to `docs/superpowers/specs/2026-10-07-duo-fold-layout-design.md`, found while testing on the Duo. (1) `FoldPane` wraps whole tabs in `ContentView`, not each screen. (2) The pane edge is the region frame plus its margins (435.5 pt). (3) The Decisions path is `[Decision]` instead of `NavigationPath`, and the `DecisionsSelection` helper picks the detail. (4) Decisions skips `FoldPane` in wide landscape, because it splits there.
**Why:** Whole-tab wrapping keeps one fold rule in one place. The margins are part of the fold, so the pane must stop at the frame plus margins. A typed path lets the split view choose the detail. A split view cannot also sit in a half pane. Four bugs on the Duo shaped the rest. The pane overshot the fold because it measured from the screen edge, not from its own origin. The tab rail's trailing inset shrank the left pane by 84 pt, so the left pane gets extra width and is cut at the fold. A plain clip hid the full-screen navigation bar (back button, Edit, trash, logo), so the cut now reaches the screen edge on the side away from the fold. Extra height on the top pane hid the last 83 pt of scrolling content, so the top pane gets no extra height.
**Alternative considered:** Wrap each screen in `FoldPane`. Keep `NavigationPath` and map it to a decision. Both add code for no gain.

## 2026-10-07 (Fold layout uses system APIs only, for now)
**Decision:** The fold layout uses system APIs only (`ReservedRegion`, `ArrangementView`, `GeometryProxy`). It has no hard-coded Duo sizes and no device checks.
**Why:** Duo behaviour is not well understood yet, and good examples do not exist. System values follow the device if Apple changes it.
**Alternative considered:** Hard-code the Duo fold size. Rejected: it breaks when the hardware or the OS changes.

## 2026-10-07 (Fold layout choices Geoff may amend)
**Decision:** Three layout choices stand for now, and Geoff keeps the right to change them. (1) Only Decisions splits into two panes. (2) Partly open screens that do not split use one half: the top half in portrait, the left half in landscape. (3) Fully open screens that do not split use a centred column up to 600 pt. Each choice is one constant or one view, so a change is small.
**Why:** The choices are a judgment call made before anyone has used the Duo daily. A simple rule per case is easy to move later.
**Alternative considered:** Split more screens (for example Insights), or fill both halves when partly open. Left for a later look, after use on the Duo.

## 2026-10-07 (Fold layout changes only a foldable device)
**Decision:** Only a device with a fold gets the fold layout. The app detects it from the system: a foldable device reports a `.division` region even when fully open (inactive), and every other device reports none. The posture has three cases: `flat` (any other device, and the closed Duo: the whole screen, as before), `unfolded` (the Duo fully open: a centred column up to 600 pt, two-pane Decisions in wide landscape) and `folded` (the Duo partly open: one half, two-pane Decisions in wide landscape).
**Why:** The final review found that a width rule changes every iPhone in landscape (874 to 956 pt wide), and gives a Pro Max iPhone the two-pane Decisions. Width alone cannot tell a Pro Max in landscape (956 pt) from the open Duo (951 pt). The review also found that one view branch per layout rebuilt the whole tab when the Duo folded, which wiped a half-typed Log entry. `FoldPane` now uses one view chain for every layout.
**Alternative considered:** Raise the width threshold above 956 pt. Rejected: the open Duo is narrower than a Pro Max.

## 2026-10-07 (Rotating the Duo rebuilds the Decisions detail)
**Decision:** Accept it for now. When the Duo rotates between two-pane landscape and one column, the Decisions detail view is rebuilt. The selected decision stays (it lives in the path), but text typed in an open Mark Outcome or Edit sheet is lost.
**Why:** The two layouts use different containers (`ArrangementView` and `NavigationStack`), so one view chain cannot cover both. It affects only the Duo, and only a rotation with a sheet open.
**Alternative considered:** Keep one container and fake the split. Rejected: more code and more risk for a rare case.

## 2026-10-09 (Outcome Trends labels: drop the ones that touch)
**Decision:** The Outcome Trends x-axis resolves label collisions greedily. It keeps a label only if it does not touch the last kept label, and drops the rest. The phone shows every second label at the default text size.
**Why:** The labels ran together ("Aug 23Aug 30") on the wide Duo layouts. A greedy check works at any width and text size, with no tuning per device.
**Alternative considered:** A stride computed from the chart width. Rejected: it needs a guess of the label width and breaks when the text size or date format changes.

## 2026-10-09 (Purchase sheet follows concept A, "Show the output")
**Decision:** The Unlock Reflection sheet shows a fixed, labelled Example of the output (eight Work decisions, Expected against Turned out) above the feature list, under the headline "See what your decisions add up to." The price stays in the buy button, and the buttons keep the 2026-10-02 pinning rule. The Example headline uses Look Back's own wording ("Your Work decisions tend to beat your predictions"), not the mockup's "You undersell", so the sheet shows only what the product shows (see 2026-10-05). The third feature row is concept A's Look Back line, now that `reflection-depth` is merged.
**Why:** Geoff picked concept A (`ASC Screenshots/IAP/A — Show the output@2x.png`) before launch. A sample of the result sells Reflection better than a list of feature names. The sample is drawn in SwiftUI, not shipped as an image, so it follows light and dark mode and Dynamic Type.
**Alternative considered:** Concept C ("Maker's note"). Using a screenshot of real output as an image asset (fixed colours, no Dynamic Type, and it would need redrawing for each size).

## 2026-10-09 (Log review date refreshes when the day changes, not at midnight)
**Decision:** The Log review date is refreshed (`ReviewDatePreset.refreshed`) when `store.today` changes, which happens when the app returns to the foreground on a new day. A review date that is no longer in the future moves to the new tomorrow. A date the user picked that is still in the future stays.
**Why:** A suspended app gets no timer at midnight. The date only matters when the user next looks at the form, so the foreground change is enough, and it needs no timer.
**Alternative considered:** A timer that fires at midnight. Rejected: more code, and it does not run while the app is suspended.
## 2026-10-05 (Reflection output: code does the work, the model fills narrow fields)
**Decision:** Each Reflection call gives the model one narrow field per job. Code does the grouping, matching, counting and labels. Patterns writes one sentence per result group (worse than predicted, as predicted, better). The decision reflection gets the other decisions in its category already split into "went the same way" and "went differently", and fills one `echo` sentence. Look Back shows a count line built in code and one model sentence per group under a fixed label. Code drops any group sentence when that group is empty.
**Why:** Each time the model did that work itself, it failed on the test data (`docs/fixtures/reflection-notes.json`). A free list of observations repeated a line or skipped a group. With one plain list of other decisions, it said "breaks the pattern" for decisions that matched it. Unlabeled group sentences began "All of these decisions…" and did not name the group. Small wording changes moved the output a lot; a fixed shape did not. Details: `docs/superpowers/archive/2026-10-05-reflection-depth.md`.
**Alternative considered:** Tune the instruction wording. Four wording versions for Patterns each fixed one fault and caused another.

## 2026-10-05 (Patterns reads the notes, not the Insights numbers)
**Decision:** The Patterns prompt sends the notes, grouped by the first result against the prediction, up to 15 per group, each cut to 140 characters. It sends one context line with the count per group. It no longer sends Good %, accuracy, trend, category and stakes tables, or the average optimism lean. A decision's revisit and outcome notes go in the group of its first result. Below 2 notes on marked decisions, the card shows "Patterns read your notes. Add a note when you log or mark a decision." in place of the control, for buyers and non-buyers alike.
**Why:** The old output restated the Insights cards, so the paid feature said nothing new. The average optimism lean said "well calibrated" for 6 decisions that went worse and 7 that went better. The budget fits the 4,096-token context on iOS 26 (the iOS 27 simulator reports 8,192). Geoff approved the no-lock line: a non-buyer who adds notes meets the locked Clean Up Note button.
**Alternative considered:** Keep the numbers and add notes (more tokens, and the model kept restating the numbers). Send only the 8 newest notes (missed the themes).

## 2026-10-05 (Decision reflection history: other decisions, not only earlier ones)
**Decision:** The decision reflection reads up to 5 other marked decisions in the same category, newest first, whether they came before or after this one. It needs 2 or more; with fewer, the prompt is as before.
**Why:** The first decision in a category would get no history if only earlier ones counted. A reflection on an old decision also gains from what came after it.
**Alternative considered:** Earlier decisions only (the spec's first version).

## 2026-10-05 (Look Back on the Log screen; Clean Up Note leaves the purchase screen)
**Decision:** Look Back sits on the Log screen between Stakes and Expected Outcome, so the user sees it before the prediction. It matches on category only and uses the 5 newest marked decisions; stakes is a tag, not a filter. It needs 2 marked decisions in the category and shows "N to go" below that. The "Unlock Reflection" sheet lists Patterns, the decision reflection and Look Back. Clean Up Note stays in the unlock but is not listed.
**Why:** The paid features must say something the free app cannot. Clean Up Note overlaps Apple's Writing Tools, so it should not carry the price; Geoff chose to keep it as something buyers discover. Category plus stakes would rarely reach the threshold. Geoff accepted that non-buyers now meet the Look Back lock on the Log screen when a category has 2 or more marked decisions.
**Alternative considered:** A saved monthly review, or a free first try, as the extra feature. Listing Clean Up Note as a fourth item.

## 2026-10-05 (Quotation marks break the model's structured lines)
**Decision:** Reflection instructions do not ask the model to quote the user in quotation marks.
**Why:** Asked to quote the user's words in quotation marks, the model split one Patterns sentence into the fragments "and" and ".". Validation now also drops any Patterns or Look Back line of fewer than 3 words.
**Alternative considered:** Keep the quotes and repair the fragments (not reliable).

## 2026-10-05 (Look Back headline and bars; code removes the group opening)
**Decision:** Look Back adds a headline and two stacked bars (Expected, Turned out) above the model's sentences. Code builds both from every marked decision in the category; the prompt still reads the 5 newest. The headline needs 5 decisions, a group with more than half of them, and a lead of 2 over every other group. It reads "Your <Category> decisions tend to beat your predictions", "…tend to fall short of your predictions" or "Your <Category> predictions tend to hold up". Patterns gets the same fixed group labels as Look Back. Code removes the group opening ("The notes on decisions that went worse than predicted all mention …") from each sentence.
**Why:** Geoff's paywall concept showed this card as an example. A visual card from code says something the free app does not show, and works with no notes. The paywall should only show what the product shows. Counting directions avoids the averaging blind spot of the free Optimism card (6 worse and 7 better read "Well calibrated"); without the margin, 7 against 6 still read as a lean. Asking the model to start with the trait made it copy one note per group, so code does the cut and the model output stays the same.
**Alternative considered:** Bars over the 5 newest only (the headline could then appear only at exactly 5). "You undersell / oversell your <Category> decisions" (the mockup's wording; "oversell" reads awkwardly, and the instructions avoid personality labels). Prompt wording for the opening (failed, see the plan, chunk 6).

## 2026-10-09 (Splash once a day; the launch screen is the app background)
**Decision:** The splash shows on the first cold launch of each day (`lastSplashDate`, `SplashSchedule`). The launch screen is `OffshootBackground` with no image. The splash green fades in with the icon and title.
**Why:** The 2026-10-07 green launch screen showed on every cold launch, but the splash ran only once after install, so later launches showed bare green and looked broken. Geoff wants the full splash once a day and nothing on later opens. A launch screen cannot change by day, so it cannot be green on the first launch and plain afterwards. The fade turns the dark-to-green change on the first launch into a transition instead of the flash Geoff flagged on 2026-10-07.
**Alternative considered:** A green launch screen with the icon on every launch (built, commit `8fcd345`, and confirmed on the phone; Geoff did not want an icon-only screen on later opens). The splash on every launch (a 2-second wait each time).

## 2026-10-16 (Duo: Dashboard, Log and Insights use both halves in wide landscape)
**Decision:** Amends the 2026-10-07 fold design ("Amendable choices" 1 and 2). In wide landscape on the Duo, Dashboard shows the selected decision beside it, Insights splits its cards into two topic groups, and Log lists recent decisions in the picked category. Settings stays in one pane. Spec: `docs/superpowers/specs/2026-10-16-duo-wide-panes-design.md`.
**Why:** Geoff looked at the single-pane screens on the Duo and did not like the empty right half.
**Alternative considered:** Keep one pane and accept the empty half (the 2026-10-07 choice). Split Insights with chart filtering of a decisions list (later, it needs new chart interactions).

## 2026-10-16 (Duo Dashboard: the shown decision is pinned; nothing carries between one pane and two)
**Decision:** The Dashboard detail pane pins whatever it shows, the default included, until another row is tapped or the decision is deleted. A selection is not carried when the Duo changes between one pane and two, in either direction; Dashboard keeps plain pushes and has no navigation path. Log row taps open the decision in the Decisions tab, as a reminder tap does.
**Why:** Marking an outcome moves a decision out of Ready to Review. If the pane followed the default, it would jump to the next decision before the result banner, the payoff of a review, could show (found in the branch review). Carrying the selection across pane counts would need a Dashboard navigation path; the simplest option ships first.
**Alternative considered:** Recompute the default every time (jumps after a mark). Carry the selection like Decisions does (more code in both Dashboard sections).

## 2026-10-16 (Duo portrait panes: the landscape pairs, top and bottom)
**Decision:** When the Duo is partly open in portrait, Dashboard, Log, Decisions and Insights use two stacked panes with the same content as landscape. `PaneArrangement` (`single`, `sideBySide`, `stacked`) replaces the "two panes" Bool; `FoldPosture.arrangement(width:)` decides it. Stacked panes use inline titles (Decisions, Insights), and the Log hero is hidden, because each pane is only about 456 pt tall. Settings stays in one pane. Fully open portrait keeps the centred 600 pt column. The bottom pane needs no tab bar inset: its content scrolls clear of the bar (checked on the Duo, 2026-10-16).
**Why:** Geoff saw the empty bottom half after the landscape work and asked to carry the pairs over. The pane split is one parameter on `ArrangementView` (`.split.axes(.vertical)`), so one rule serves both orientations.
**Accepted, not fixed:** Opening the hinge to partly open portrait now rebuilds the four screens, as rotating the Duo already does (see 2026-10-07, "Rotating the Duo rebuilds the Decisions detail"). On the closed Duo, an open Mark Outcome sheet, a Dashboard push or an unused Clean Up Note result is lost when the Duo opens partly in portrait. The code reviewer found this. The Log form's values survive (checked on the Duo).
**Alternative considered:** Keep the top half only (the 2026-10-07 choice). A separate bottom-pane layout per screen (more code for no gain).

## 2026-10-17 (Free Look Back in 2.0; paid Reflection in November 2.1.0)
**Decision:** Ship 2.0 with immediate free Look Back counts, bars, Copy, and the existing calculated headline on iOS 18.6+. Disable paid production Reflection before model/StoreKit/debug setup; preserve its code and all user notes. This supersedes the earlier 2.0 IAP/paid Look Back instructions.
**Why:** Geoff's real examples contain outcome contradictions, altered comparisons, and unsupported repetition. The paid upgrade owns the November 2026 2.1.0 cycle, gated by scored real-note evaluation and physical-device acceptance; free Look Back stays free. Spec: `docs/superpowers/specs/2026-10-17-free-look-back-design.md`.
**Alternative considered:** Ship the filtered generated text with 2.0. Rejected by Geoff. No exact November week is assigned; unrelated platform integrations stay outside the cycle.

**Verification (2026-10-17):** Geoff confirmed "Build 10 looks good on my phone" and approved merging `dev/free-look-back` into `main` locally. This closes the build 10 device gate. Listing/screenshots, IAP exclusion, push, upload, and submission remain separate release steps.

**Integration (2026-10-17):** Fast-forwarded `dev/free-look-back` into `main` at `76107ed`. The merged app passed 202 tests in 24 suites on iPhone 18 Pro (iOS 27.0). Geoff handles `git push origin main`; no push, upload, or submission was performed.
