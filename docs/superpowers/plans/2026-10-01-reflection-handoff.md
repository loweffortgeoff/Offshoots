# Reflection — Handoff After Task 3

Date: 2026-10-01. Machine: Mac mini (Xcode 27.0, iOS 27.0 SDK).
Plan: `docs/superpowers/plans/2026-10-01-reflection.md` (6 tasks).
Spec: `docs/superpowers/specs/2026-09-30-reflection-design.md`.

Read this first in the next session. Then read the plan's Task 4 only.

## Where things stand

Branch `reflection`, not pushed and not merged. It merges to `main` after Task 6.
The full test suite passes (98 of 98).

| Task | State | Commits |
|---|---|---|
| 1. Policy layer, protocol, fake | Done | 116c139, 9ae2645, b377b2d |
| 2. Live service, Patterns on Insights | Done | e6b1205, de9d853, 7a26cde, 5ea0e89 |
| 3. Decision reflection on Decision Detail | Done | ce81134, 90423d3, 06d4c87 |
| 4. Clean Up Note on the three note fields | Next | — |
| 5. StoreKit entitlement, paywall, Restore | Not started | — |
| 6. Docs, listing, release notes | Not started | — |

Geoff confirmed the plan's five assumptions at STOP 1: four gate states;
Clean Up Note needs 3 words and allows up to 1,500 characters; the Settings
section shows only where the gate is not `hidden`; Edit Decision is out of
scope; Copy uses `UIPasteboard`.

On `main` (separate from Reflection): the revisit-row fix for accessibility
text sizes, commits eea6c7f and b2240e6. These are merged, not pushed.

**Uncommitted in the working tree:** Geoff's edit to the shared
`Offshoots.xcscheme`. It adds the launch argument `ReflectionUnlockOnly`
without the leading dash, so it does nothing. Do not stage it. Ask Geoff
before you change or commit it.

## Start of Task 4

1. Switch to `reflection`.
2. **First change (Geoff approved at STOP 3):** tell the model to leave
   "What is repeating" empty when nothing repeats. Edit
   `ReflectionPromptBuilder.decisionInstructions` and the `@Guide` text for
   `repeating` in `LiveReflectionService`. The card already hides an empty
   section. Re-test on the simulator with a decision that has only revisits
   and no notes (decision B in the test data below). Before the change, its
   lines said nothing useful, for example "The timeline includes specific
   days marked in the journal."
3. Then the plan's Task 4: Clean Up Note on the Log, Mark Outcome and Revisit
   note fields.
4. Before Task 5: create the non-consumable in App Store Connect.

## Rules to carry forward

- **Hide each surface at the call site, not inside the card.** Show it only
  when `reflection.gate != .hidden`, next to the eligibility check, with
  `@Environment(ReflectionCenter.self) private var reflection`. Removing the
  view drops its in-memory result, so a stale result cannot come back.
  `AnalyticsView` and `DecisionDetailView` do this. Task 4's suggestion row
  should do the same. A `Group` with an `onChange` does not work: a `Group`
  hands its modifiers to its children.
- **Paywalled state:** until Task 5, a launch with no argument shows the card
  title with nothing under it. This is expected.
- **Previews:** any preview that shows or pushes a view that reads
  `ReflectionCenter` needs `.environment(ReflectionCenter.make())`.
- **Stops:** stop at the end of every task and show Geoff. Do not chain tasks.

## How we test

- **Unit tests:** `xcodebuild … -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' test`.
- **Simulator:** iPhone 18 Pro, iOS 27.0, UDID `204520A6-E5B5-447D-8A6B-028317014DD8`.
  Say that you take it, and say when you release it.
- **Launch arguments:** `-ReflectionFake` gives canned output, unlocked.
  `-ReflectionUnlockOnly` uses the real model, unlocked.
- **The simulator runs the real on-device model** on the Mac mini. The plan
  says it does not; that is wrong. Greedy sampling gives the same output for
  the same input, so a prompt change can be re-tested on the simulator.
  Geoff skipped the device runs for now.
- **Test data:** `scripts/seed.sh insights-seed` for Patterns.
  `scripts/seed.sh screenshots` for Decision Detail. For a long note, add
  decisions with these shapes to a copy of `screenshots.json` in the
  scratchpad, and copy it to the app's `Documents/decisions.json` with the
  app closed:
  - A: a log note only
  - B: two revisits with no notes
  - C: a note of about 10,000 characters
- **The first tap after `simctl launch` is often lost.** Send it again.

## Real model results so far (simulator, greedy)

- **Patterns (insights-seed):** after the prompt change, all four observations
  were true, with no advice. Before it, one observation was false: it gave
  Work the global "one step off" count.
- **Decision reflection:**
  - A: accurate.
  - B: the summary and question were accurate; "What is repeating" was filler.
    The first change in Task 4 fixes this.
  - C: no error.
  - None of A, B or C gave advice or showed an empty section.

## Open minor findings (none block)

- `ReflectionRun` does not cancel when a card closes. A card that closes
  mid-run wastes one model call.
- The fake Clean Up adds "Cleaned up: " before the note. That text shows in
  any simulator screenshot of Clean Up (Task 6).
- The prompt-injection test cannot fail as written. The protection comes from
  the structure: user text goes only into the prompt, never the instructions.
- `.appleIntelligenceNotEnabled` maps to `unsupported`. A capable device with
  Apple Intelligence off shows nothing, and the user gets no hint.
- `validated()` runs inside each generator, and the fake skips it.
- `LiveReflectionService` has a dead `catch let error as ReflectionError`.
- The `.notReady` button has no tint. It is disabled, so this is not visible.
- Previews use `ReflectionCenter.make()`. They show the locked state or no
  card at all.
- Older decisions marked before their review date overstate
  `daysToFirstOutcome`. This comes from the existing `resolvedDate` fallback.
- `ReflectionText.clean` traps if `limit` is 0. Every caller passes 120 or
  more.

## Not checked yet

- Light mode on the simulator: the app's theme setting stayed on Dark.
- VoiceOver with VoiceOver running: the header traits were only checked in
  the code.
- Any run on a physical device.
