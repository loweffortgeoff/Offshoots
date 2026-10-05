# Reflection Depth — Design Spec

Status: reviewed, 2026-10-05. Open questions closed. No code yet.
Branch: `reflection-depth`.
Builds on: `docs/superpowers/specs/2026-09-30-reflection-design.md`.

## Problem

Reflection is a $5.99 unlock, but its output is thin. The output says what the user
already knows:

- **Patterns** gets the same numbers that Insights shows (Good %, accuracy, optimism,
  trend, category counts). It reads only the 8 newest notes, each cut to 140 characters.
  It turns the dashboard into sentences.
- **Decision reflection** sees one decision only. With no notes, it says little more than
  "you predicted Good and got Good".
- **Clean Up Note** overlaps Apple's Writing Tools, which proofread for free on every
  device that can run Reflection. (From general knowledge; not checked on a device.)

The release is not finished: the in-app purchase is not "Ready to Submit" yet. A change
now costs nothing in the store.

## Goal

Make every Reflection output say something the free app cannot. The model reads the
user's own words against what actually happened, and it compares a decision with
similar past decisions. Add one new surface, **Look Back**, on the Log screen.

## Rules that do not change

All rules from the 2026-09-30 spec stay: user-triggered only, nothing saved, no advice on
what to choose, no scores or labels, no Refresh, a hidden surface draws nothing, the gate
has the same four states, and user text never goes into the instructions.

## Part A — Better output

### A1. Test fixture and baseline

- New fixture `docs/fixtures/reflection-notes.json`: about 15 marked decisions with
  realistic notes. Some go worse than predicted, some go better, some match. The notes
  in each group share themes that a reader could find (for example, rushed money
  decisions that went worse, health decisions that went better than feared).
- Before any prompt change, run Patterns and two decision reflections on the simulator
  (Mac mini, iOS 27.0, real model). Save the output in this spec's plan as the baseline.
  Greedy sampling gives the same output for the same input, so the comparison is fair.
- Measure the prompt size. **Assumption to check:** the on-device context window is about
  4,096 tokens for instructions, prompt and response together. Check whether the SDK has a
  token-count API. If not, measure by growing the fixture until `exceededContextWindowSize`.
  Set the note budget from the result.

### A2. Patterns reads the notes

- New digest shape. Notes are grouped by how the first result compared with the
  prediction: **worse than predicted**, **as predicted**, **better than predicted**. Each
  note keeps its category and stakes as a short tag.
- Send as many notes as the budget allows, newest first within each group. Each group
  gets a fair share of the budget, so one large group cannot push out the others.
- Remove the lines that repeat the Insights cards: Good %, accuracy counts, trend. Keep
  one short context line (marked count, optimism lean) so the model knows the scale.
- New instructions: compare the groups. Name what the notes in one group share that the
  other groups do not. Quote or closely echo the user's words. Do not restate counts or
  percentages.
- With fewer than 2 notes in total, Patterns shows a not-ready line: "Patterns read your
  notes. Add a note when you log or mark a decision." The 5-marked threshold stays.

### A3. Decision reflection compares with similar decisions

- New digest field `history`: earlier marked decisions in the **same category**, before
  this one. For each: first result against the prediction (worse, as predicted, better),
  and its outcome note cut short. Cap at the 5 newest.
- If the same category has fewer than 2, the field is empty and the prompt is as today.
- New instructions: say whether this decision follows or breaks the earlier pattern in
  this category. Keep the rest of the shape (summary, what repeats, next question).

## Part B — Look Back

### Where

The Log screen, below the category and stakes pickers, above the prediction picker. The
user sees it before they choose a prediction.

### What it shows

- A control: `Look Back`. Tap only; nothing runs by itself.
- The result: one or two sentences. They describe how earlier decisions in this category
  went against their predictions, and echo one note from them. Example shape: "Your last
  four Money decisions went worse than you predicted. Two notes mention deciding in a
  hurry."
- No advice. No predicted result. The text never says what to choose or what to expect.

### When it shows

- Same gate as the other surfaces (`hidden`, `notReady`, `paywalled`, `enabled`).
- Needs at least 2 earlier marked decisions in the chosen category. Below that, a
  not-ready line: "Look Back needs 2 marked Money decisions. 1 to go."
- A change of category or stakes clears the result.

### Matching rule

Same category only. Stakes is sent as a tag on each line, so the model can mention it,
but it does not filter. Category plus stakes would rarely reach the threshold.

### Code

- `ReflectionDigestBuilder.lookBack(category:stakes:in:)` builds the digest. It shares
  the history helper with A3.
- `ReflectionGenerating` gets `lookBack(digest:)`. The fake generator gets canned output.
- New view `LookBackCard` in `Reflection/`. Hidden at the call site, like the other cards.

## Part C — Paywall copy

The "Unlock Reflection" sheet lists three features. New list: Patterns, Decision
reflection, Look Back. Clean Up Note stays in the app for buyers, but it leaves the
feature list: the purchase screen lists only the features that justify the price. Buyers
find Clean Up Note on the note fields. README, ASC_LISTING and RELEASE_NOTES follow.

## Chunks

Each chunk ends at a stop for review.

1. A1: fixture, baseline output, context measurement.
2. A2: Patterns rework, tests, before-and-after output.
3. A3: decision history, tests, before-and-after output.
4. B: Look Back.
5. C: paywall copy, README, DECISIONS, ASC_LISTING, RELEASE_NOTES.

## Tests

- Digest builder: grouping by result, budget split across groups, history cap and order,
  category match, thresholds.
- Prompt builder: no counts or percentages from Insights in the Patterns prompt; user
  text only after the data line.
- Gate and eligibility: the new not-ready lines.
- Real output is checked by eye on the simulator against the baseline. It is not a unit test.

## Out of scope

Saved output, a monthly review, a free first try, matching on stakes, any change to
Clean Up Note's behavior, price changes.

## Closed questions

1. Name: **Look Back** (Geoff, 2026-10-05).
2. Clean Up Note leaves the purchase screen. It stays in the app as something buyers
   discover. The purchase screen does not list low-value items (Geoff, 2026-10-05).
