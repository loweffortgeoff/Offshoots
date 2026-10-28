# Reflection context and pairing findings (2026-10-28)

Status: prototype, uncommitted on `dev/paid-reflection`. It does not change the
2.0 scope: `paidFeaturesEnabled` stays off, and free Look Back is untouched.
Measured on the Mac mini, iPhone 18 Pro simulator, iOS 27.0, Xcode 27.1
(27A9275). Not run on a phone, and not run end to end in the app.

## Question

Patterns hallucinated connections, missed real ones, and repeated notes back.
Was the model short of context, and would more context help?

## What the model read before

- Patterns and the single-decision reading read `ReflectionSourceSnapshot`,
  newest first, cut at 1,800 UTF-8 bytes (about 450 tokens) of a 4,096-token
  context. On `reflection-notes` (17 marked decisions) it read 6.
- Each line carried full ISO timestamps. Stakes and Hindsight answers were
  never in the prompt.
- The single-decision reading reads only its own decision.
  `decisionPrompt` returns early on the snapshot, so its history lines never
  run.

## Step 1: token budget, compact format, Hindsight in the prompt

- `LiveReflectionService.snapshot(for:decisions:)` fills
  `min(contextSize, 4096)`, minus instructions, schema, response and a 64-token
  margin. It counts each record once and sums the counts, and stops counting
  once even the cheapest record seen cannot fit (each count call costs about
  25 ms). Before iOS 26.4, or if counting fails, it uses the byte bound.
- The request controller now takes the snapshot inside the request, through
  `ReflectionGenerating.snapshot(for:decisions:)`. `ReflectionFreshness`
  compares by decision ID and content, so a larger selection does not mark
  readings stale.
- The prompt uses day numbers and adds stakes and Hindsight labels. Evidence
  keys and evidence text are unchanged, so saved readings display as before.
  The Hindsight answer is never citable evidence.

| | Before | After |
|---|---|---|
| Decisions read (`reflection-notes`) | 6 of 17 | 17 of 17 |
| Patterns prompt | 872 tokens | 1,553 tokens |
| 153-decision journal | 6 read | 33 read; selection 1.9 s (4.4 s before the per-record count) |
| Patterns, 17 decisions, total | 1.4 s | 2.3 s |
| `reflection-notes` result | Plumber + angry reply as "checking information" (wrong) | Repaint + plumber, both prepared (right) |
| `reflection-hindsight` result | — | Plumber + angry reply as "quick under pressure" (wrong) |

Result: more context solved the reading-only-6 problem. The model still
paired the wrong records, and Hindsight labels did not help in this sample.

## Step 2: code chooses the pair (`ReflectionPairing`)

- Score = 3 × note similarity + 1 for a shared result direction + 1 for
  Hindsight answers in the same group. Similarity is `NLEmbedding` sentence
  vectors for the notes' dominant language, else shared words. Pairs below
  0.5 similarity are dropped.
- The model sees only the two notes with their titles, writes one sentence or
  leaves it empty, and gets at most two pairs. Code supplies the evidence keys.
- `choosesPairs = false` keeps the free-choice path for comparison.

Graded on the 23 Patterns cases in `reflection-acceptance.json` by
`pairingComparison()`. The grade is looser than the evaluation rubric: pass
means an eligible case cites only expected decisions, or an ineligible case
cites none. It does not judge wording.

| | Free choice | Code-chosen pairs |
|---|---|---|
| Passed | 21 / 23 | 20 / 23 |
| `same-outcome-different-notes` (should abstain) | fail | pass |
| `unrelated` (should abstain) | fail | fail |
| `cross-category-immediacy`, `work-immediate-commitments` | pass | fail (no pair) |

Pairs mode wrote more concrete sentences ("a purchase made quickly after
noticing a time limit").

Lessons:

1. Giving the model the shared facts ("both went better than predicted")
   made it repeat them. They now only rank the pair.
2. The sentence embedding measures topic, not behaviour. The unrelated
   caffeine and old-friend notes scored 0.50; "bought it in a hurry" and
   "said yes before checking my calendar" scored below that. No threshold
   separates them.
3. Mixed Spanish and French notes get no dominant language, so they fall back
   to shared words, and in the French case the model copied a note.

## Not tried

Choosing pairs by behaviour, not topic: one batched model call tags each
written note from a fixed list (acted quickly, prepared first, dreaded it,
outside pressure, and so on), and code pairs notes that share a tag. Sorting
into a fixed list suits a small model better than finding connections, and
the tags can be checked.

## Open decisions

- `hindsightDoesNotChangeFreeAnalyticsOrModelPrompt` was narrowed to
  `...OrModelSelection`: Hindsight may now appear in the prompt but must not
  change analytics, which decisions are read, or the evidence. That loosens
  the 2026-10-24 Hindsight design and needs a DECISIONS entry if kept.
- Phone timing, an in-app run with `-ReflectionUnlockOnly`, and the
  single-decision reading's own-decision-only scope are unchecked.

## Files

Changed: `LiveReflectionService`, `ReflectionGenerating`,
`ReflectionPromptBuilder`, `ReflectionProviderCoordinator`,
`ReflectionRequestController`, `ReflectionSourceSnapshot`, and tests
`HindsightDataTests`, `ReflectionEvidenceTests`, `ReflectionLiveOutputTests`,
`ReflectionPromptBuilderTests`. New: `ReflectionPairing.swift`,
`ReflectionPairingTests.swift`, `docs/fixtures/reflection-hindsight.json`.
291 unit tests pass. Live harness cases: `patterns(fixture:)`,
`largeJournalSnapshotTime()`, `pairingComparison()`.
