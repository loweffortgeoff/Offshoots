# Reflection Depth — Plan

Spec: `docs/superpowers/specs/2026-10-05-reflection-depth-design.md`.
Branch: `reflection-depth`. Each chunk ends at a stop for Geoff's review.

## Tool: the live output harness

`OffshootsTests/ReflectionLiveOutputTests.swift` runs the real on-device model on a
fixture and prints the prompt sizes and the output. It is off by default. Turn it on with
the `REFLECTION_LIVE=1` environment variable (`TEST_RUNNER_REFLECTION_LIVE=1` on the
`xcodebuild` command line):

```
TEST_RUNNER_REFLECTION_LIVE=1 TEST_RUNNER_REFLECTION_LIVE_OUT=/tmp/reflection-live.txt xcodebuild -project Offshoots.xcodeproj -scheme Offshoots \
  -destination 'platform=iOS Simulator,id=<UDID>' \
  -only-testing:OffshootsTests/ReflectionLiveOutputTests test
```

The tests run in a cloned simulator, so printed text does not reach the xcodebuild log.
The output goes to the `REFLECTION_LIVE_OUT` file on the Mac. The MacBook Pro has two
simulators named "iPhone 18 Pro" on iOS 27.0; pick one with `id=` (this plan used
`22F3F961-2FD9-47A0-9158-24A94F6871B4`).

Greedy sampling gives the same output for the same input, so a before-and-after
comparison is fair. Every chunk that changes a prompt runs it and records the output
below.

## Chunk 1 — Fixture, baseline, context size

- [x] `docs/fixtures/reflection-notes.json`: 17 marked decisions and 1 open one, with notes.
  Themes a reader can find: decisions made in a hurry went worse than predicted;
  decisions the user dreaded went better; decisions planned with research went as
  predicted. Money has 5 marked decisions, so Look Back and the decision history have data.
- [x] `ReflectionNotesFixtureTests`: pins the counts per group, so a fixture edit is caught.
- [x] The live output harness (above).
- [x] Run it. Record the context size, the token counts and the baseline output below.
- [x] Set the note budget for chunk 2 from the measured numbers.

## Chunk 2 — Patterns reads the notes (spec A2)

- [x] New `PatternsDigest` shape: notes grouped worse / as predicted / better, each with a
  category and stakes tag; one context line; the Insights counts removed.
- [x] Budget: a fair share per group, newest first, cut to the measured budget.
- [x] New instructions and prompt. Not-ready line when fewer than 2 notes.
- [x] Tests for the digest, the budget and the prompt.
- [x] Harness run: record the new output next to the baseline.

## Chunk 3 — Decision history (spec A3)

- [x] `history` on `DecisionDigest`: up to 5 other marked decisions in the same category.
- [x] The prompt splits the history into same result and different result.
- [x] New `echo` output field and its "In other <Category> decisions" section on the card.
- [x] Tests. Harness run: record the new output.

## Chunk 4 — Look Back (spec B)

- [x] `ReflectionDigestBuilder.lookBack(category:in:)`, sharing the history helper.
- [x] `ReflectionGenerating.lookBack(digest:)`, the live and fake versions.
- [x] `LookBackCard` on the Log screen, below Stakes, above Expected Outcome, hidden at
  the call site.
- [x] "To go" line below 2 marked decisions in the category. A category change clears the result.
- [x] Tests. Harness run. Simulator check (see below).

## Chunk 5 — Copy and docs (spec C)

- [x] Unlock Reflection sheet: Patterns, Decision reflection, Look Back. Clean Up Note
  leaves the list.
- [x] README, ASC_LISTING, RELEASE_NOTES, DECISIONS, CHANGELOG, TODO.

## Chunk 6 — Look Back headline and bars; group labels (after Geoff's paywall concept)

- [x] `LookBackStats`: every marked decision in the category, not capped. The prompt still
  reads the 5 newest. Count line, headline and bars all read the stats, so they agree.
- [x] Headline only from 5 decisions, when one group holds more than half and leads every
  other group by 2. Directions are counted, never averaged.
- [x] `LookBackBars`: Expected and Turned out as stacked bars, worst outcome on the left,
  axes hidden, labels and legend in SwiftUI, chart text capped at xxxLarge, one VoiceOver label.
- [x] Patterns gets the same fixed group labels as Look Back (`ReflectionGroupLine`,
  `ReflectionGroupLinesView`).
- [x] Code removes the group opening ("The notes on decisions that went worse than
  predicted all mention …") from each sentence, because the label names the group.
- [x] Tests. Harness run. Simulator check (see below).

## Measurements and output

### Chunk 1 — 2026-10-05, MacBook Pro, Xcode 27.0, iPhone 18 Pro simulator (iOS 27.0)

**The real model runs on this Mac's simulator.** `SystemLanguageModel.default.availability`
is `.available`, and each call takes 3 to 7 seconds.

**Context size.** The simulator on iOS 27.0 reports 8,192 tokens. The SDK returns a fixed
4,096 on iOS 26 (read in the iOS 27.0 SDK's `FoundationModels` interface). The app supports
iOS 26, so every budget must fit 4,096.

**Token counts today** (instructions are counted as a prompt string, so they are close,
not exact):

| Call | Instructions | Prompt | Schema | Total before the response | Response cap |
|---|---|---|---|---|---|
| Patterns (8 notes) | 85 | 314 | 73 | 472 | 300 |
| Decision: launch project | 109 | 111 | 134 | 354 | 400 |
| Decision: laptop | 109 | 90 | 134 | 333 | 400 |

**Note budget for chunk 2.** One note of up to 140 characters costs about 10 to 35 tokens.
Fixed parts plus the response cost about 900 tokens. That leaves about 3,000 tokens of
the 4,096. Budget: **at most 15 notes per group, 45 in total**, each cut to 140 characters.
The worst case is about 1,600 tokens, which leaves a wide margin. Chunk 2 adds a test that
the worst-case prompt stays under a fixed character cap.

**Baseline Patterns output:**
- Most decisions were marked as good or great, but few matched the prediction exactly.
- The number of decisions with exact matches is low across all categories, including money, work, health, relationships, and home.
- Home decisions had a higher rate of exact matches compared to other categories.
- One decision was revisited and the outcome changed.

What this shows: every line restates a count. None of the three themes in the notes
(hurry → worse, dread → better, research → as predicted) appears. The prompt sends only
the 8 newest notes, and they are not tied to any result.

Also: the digest says "Optimism: well calibrated over 17 decisions". The fixture has 6
decisions that went worse and 7 that went better. The average gap hides two opposite
misses. Chunk 2's grouping shows the model both sides.

**Baseline decision reflection — "Say yes to leading the launch project":**
- Summary: The decision to lead the launch project began with a positive intention but shifted to neutral after handing off reporting duties. The initial setback followed by a quiet period shows a change in focus after the early pressure eased.
- Repeating: Said yes in a meeting before checking the calendar / Lost two weekends to the project / Outcome shifted from bad to neutral after handing off reporting
- Next: What does the timing of the handover reveal about how you manage time under pressure?

**Baseline decision reflection — "Upgrade to the new laptop":**
- Summary: The decision to upgrade to the new laptop began with a sense of urgency due to a sale ending soon. The outcome showed the old laptop was sufficient, and the choice did not lead to the expected result.
- Repeating: The timing of the decision tied to a deadline. / A purchase made quickly without full consideration. / The expectation of a positive outcome despite the outcome being different.
- Next: What did the timing of past decisions reveal about your response to pressure?

What this shows: the reflection reads the notes well, but "Repeating" only repeats facts
from this one decision. It cannot say that the gym plan (also Money, also signed "on the
spot") went the same way. Chunk 3 gives it that history.

### Chunk 2 — 2026-10-05, same Mac and simulator

**Token counts after the change:** instructions 143, prompt 670, schema 156, total 969
before the response (17 decisions, 34 notes). The worst case (45 notes of 140
characters) is pinned under 8,000 characters by `theWorstCasePatternsPromptStaysSmall`.

**Prompt iterations** (greedy, same input each time):

| Version | Result |
|---|---|
| A. Free list, "compare the groups, echo the user's words" | All three themes found. Line 4 repeated line 1. Every line starts "Notes from decisions that…". |
| B. A + "speak as you" + "quote the user's words in quotation marks" | Broken: one sentence split into "and" and ".". Quotation marks inside the output break the structured list. |
| C. A + "speak as you", no quotation marks | Lines 2–4 good. Line 1 invented a theme ("settled or dropped out"). |
| D. A + "each about a different idea" | Three of four lines about the worse group. The planning theme was lost. |
| **E. One sentence per group (`worse`, `asPredicted`, `better` fields)** | **Chosen.** Each group covered once, no repeats, all accurate. |

Lesson: small wording changes move this model a lot. A fixed output shape is more
reliable than a wording rule.

**Chunk 2 Patterns output (version E):**
- The notes on decisions that went worse than predicted all mention actions taken quickly or under pressure.
- The notes on decisions that went as predicted all describe clear steps taken before the outcome was known.
- The notes on decisions that went better than predicted all involve unexpected positive results from effort or patience.

Compared with the baseline: every line now says something the Insights cards cannot.
Weak point: the "better" line misses the dread theme ("Dreading it", "I expect to hate
this"). Each line also starts with the same long phrase. Both are acceptable for now.

**App check:** the iPhone 18 Pro simulator (iOS 27.0), seeded with `reflection-notes`,
launched with `-ReflectionUnlockOnly`, shows the same three lines on Insights.
Not checked on screen: the "Patterns read your notes" line for fewer than 2 notes (unit
tests cover the threshold), light mode, and accessibility text sizes.

### Chunk 3 — 2026-10-05, same Mac and simulator

**Token counts:** launch project 578, laptop 617 before the response (was 354 and 333).

**First try: one plain history list, "say whether it follows or breaks the pattern".**
Both answers were wrong. Laptop: "This decision breaks the pattern of those decisions,
which mostly followed or matched expected outcomes." The gym plan and the concert
tickets were also rushed and also went worse. The launch project also got "broke the
pattern", next to the committee decision that was also an instant yes.

**Chosen: code splits the history, and a separate `echo` field.**

Launch project:
- Summary: The launch project decision started poorly and settled into neutral after handing off reporting. The outcome shifted as the initial pressure eased.
- Echo: The extra committee was agreed to right away because they asked nicely, just like the launch project.
- Repeating: Said yes quickly in a meeting / Took on more than could be managed / Lost time to the task
- Next: What did the quick agreement in the meeting reveal about how you respond to requests?

Laptop:
- Summary: The upgrade to the new laptop started well but ended with a different outcome than expected. The decision unfolded quickly, with a rush to act before a deadline, but the need did not emerge.
- Echo: Both the concert tickets and gym plan were signed on the spot because of immediate pressure.
- Repeating: Saw a deadline close / Decided quickly / Bought without full thought
- Next: What does the timing of quick choices reveal about patterns in your recent decisions?

Both echoes are correct. Small faults: "signed on the spot" fits the gym plan, not the
concert tickets ("decided in the group chat in five minutes"). The laptop summary says
it "started well"; it was predicted Good and marked Bad.

**App check:** the laptop's Decision Detail on the simulator shows the same text, with
"In other Money decisions" under "How it aged". Not checked on screen: light mode,
accessibility text sizes, a decision with no history.

**Same lesson as chunk 2:** let code do the matching, and give the model one narrow
field per job.

### Chunk 4 — 2026-10-05, same Mac and simulator

**Token counts:** Money 571, Work 509 before the response.

**First try:** unlabeled sentences. Money gave "All of these decisions were made quickly…"
and "All of these decisions involved waiting or patience…". Both were accurate, but the
reader could not tell which group each one described. Fix: a fixed label per line from code.

**Chosen output:**

Money:
- Of your last 5 Money decisions, 3 went worse than you predicted, 1 went as predicted and 1 went better.
- Went worse: All of these decisions were made quickly, often under pressure, with little time to think through the full picture.
- Went better: All of these decisions involved waiting or patience before acting, leading to a more favorable result.

(The model left "as predicted" empty: one decision, the car loan refinance.)

Work:
- Of your last 4 Work decisions, 2 went worse than you predicted and 2 went better.
- Went worse: The notes on decisions that went worse than predicted all mention a quick response to a request that led to unexpected strain.
- Went better: The notes on decisions that went better than predicted all mention preparation before the action.

**Simulator checks (iPhone 18 Pro, iOS 27.0):**
- Dark, default text, `-ReflectionUnlockOnly`: Work result shows with labels, the same text as the harness.
- Category Other (0 marked): "Look Back needs 2 marked Other decisions. 2 to go." The
  category change cleared the Work result.
- Light, AX3: the card lays out in one column. The button wraps "Look / Back" on a word
  boundary.
- Locked state: after an uninstall and reinstall (which clears the earlier StoreKit test
  purchase), a plain launch shows a bordered "Look Back" button with a lock. A tap opens
  "Unlock Reflection". Its third row still reads "Clearer notes, only when you tap"
  (chunk 5 replaces it).
- Not checked: VoiceOver reading order. The labels "Look Back" and each group label carry
  the header trait in code.

### Chunk 5 — 2026-10-05

The "Unlock Reflection" sheet lists "Pattern highlights across your decisions", "A
reflection on each decision" and "A look back before you decide" (symbol
`clock.arrow.circlepath`). Checked on the simulator from the locked Look Back button.
README, CHANGELOG, RELEASE_NOTES, ASC_LISTING, DECISIONS and TODO updated.

### Chunk 6 — 2026-10-05, MacBook Pro, iPhone 18 Pro simulator (iOS 27.0)

**First try: ask the model to start with the trait.** Both instructions said "The app
shows the group's name above each sentence, so start with the shared trait. Do not start
with 'The notes', 'These decisions' or 'All of'", and the `@Guide` text asked for "the
trait … as one short sentence that starts with that trait". Result: worse.
- Patterns copied one note per group: "Made it worse.", "Done in an hour.", "Got more
  than I asked for." The three themes were gone.
- Look Back Money still began "The notes in the worse-than-predicted group all mention…".

**Chosen: prompt reverted to chunk 4; code removes the opening.**
`ReflectionText.dropGroupOpening` cuts a known opening ("The notes …", "These decisions …",
"All of these decisions …" up to a verb such as "mention", "involved" or "were"). Any other
sentence, or one with fewer than 3 words left, is shown unchanged. The model output is the
same as before the change, word for word.

Patterns:
- Went worse: Actions taken quickly or under pressure.
- Went as predicted: Clear steps taken before the outcome was known.
- Went better: Unexpected positive results from effort or patience.

Look Back Money:
- Headline: Your Money decisions tend to fall short of your predictions
- Of the 5 Money decisions you marked, 3 went worse than you predicted, 1 went as predicted and 1 went better.
- Went worse: Made quickly, often under pressure, with little time to think through the full picture.
- Went better: Waiting or patience before acting, leading to a more favorable result.

Look Back Work (4 decisions, so no headline):
- Of the 4 Work decisions you marked, 2 went worse than you predicted and 2 went better.
- Went worse: A quick response to a request that led to unexpected strain.
- Went better: Preparation before the action.

**Headline rule, found by a test:** "more than half" alone gave "tend to beat" for 7 better
against 6 worse. The rule now also needs a lead of 2 over every other group.

**Simulator checks (`-ReflectionUnlockOnly`):**
- Dark, default text: Look Back Money shows the headline, count line, bars, legend (Bad,
  Neutral, Good, Great) and two labeled lines. Work shows no headline. Patterns shows
  three labeled lines.
- Light, AX3: each bar row stacks its label above the bar. Legend and bar labels stay at
  the xxxLarge cap.
- Not checked: VoiceOver reading of the bars (one label in code), a device, the locked state
  (unchanged code path).
