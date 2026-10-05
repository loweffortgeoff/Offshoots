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

- [ ] New `PatternsDigest` shape: notes grouped worse / as predicted / better, each with a
  category and stakes tag; one context line; the Insights counts removed.
- [ ] Budget: a fair share per group, newest first, cut to the measured budget.
- [ ] New instructions and prompt. Not-ready line when fewer than 2 notes.
- [ ] Tests for the digest, the budget and the prompt.
- [ ] Harness run: record the new output next to the baseline.

## Chunk 3 — Decision history (spec A3)

- [ ] `history` on `DecisionDigest`: up to 5 earlier marked decisions in the same category.
- [ ] Prompt and instructions use it when it has 2 or more entries.
- [ ] Tests. Harness run: record the new output.

## Chunk 4 — Look Back (spec B)

- [ ] `ReflectionDigestBuilder.lookBack(category:stakes:in:)`, sharing the history helper.
- [ ] `ReflectionGenerating.lookBack(digest:)`, the live and fake versions.
- [ ] `LookBackCard` on the Log screen, below category and stakes, hidden at the call site.
- [ ] Not-ready line below 2 marked decisions in the category. A category or stakes
  change clears the result.
- [ ] Tests. Harness run. Simulator check: light, dark, AX3, VoiceOver labels.

## Chunk 5 — Copy and docs (spec C)

- [ ] Unlock Reflection sheet: Patterns, Decision reflection, Look Back. Clean Up Note
  leaves the list.
- [ ] README, ASC_LISTING, RELEASE_NOTES, DECISIONS, CHANGELOG, TODO.

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
