# Early Engagement — Design

Date: 2026-09-26
Status: Approved in chat, awaiting spec review

## Problem

Insights need 3 marked decisions, and the trend needs 3 in each of two 30-day
windows. A new user sees "Too early" for about a month. The worries, in order:

1. **Weeks 1–3.** A few decisions are pending, and there is no reason to open the app.
2. **Weeks 3–5.** Insights exist, but the headline trend still says "Too early".
3. **Days 1–3.** The first outcome is marked, and the app gives nothing back.

## Goals

- Make short review windows the easy choice, so a new user builds a sample fast.
- Show a trend as soon as there are enough marked decisions, whatever the calendar says.
- Give something back for every marked outcome, and say what unlocks next.

## Non-goals

- A same-day ("Tonight") review. It needs a time-of-day readiness rule. Rejected in favor of whole-day presets.
- A confidence level or other new fields at log time.
- Presets on Revisit. Revisits are about a longer view.
- A dismiss control for the starter suggestions.

## Build order

Each chunk is a separate stop that Geoff reviews. Work happens on a feature branch.

1. Review-date presets
2. "So far" trend
3. Starter suggestions
4. Post-mark result line and progress copy

---

## Chunk 1 — Review-date presets

A row of chips sits above the date picker on **Log Decision** and **Edit Decision**:

**Tomorrow · 3 days · 1 week · 1 month**

- A chip sets the review date to `Date()` plus N days (1, 3, 7, 30) with
  `Calendar.date(byAdding: .day, …)`. It keeps the current time of day. Do not
  snap to `startOfDay`: `ReminderManager` normalizes from the stored time, and a
  midnight value would move every reminder to 7 AM.
- A chip is selected while the picker's day equals that preset's day
  (`Calendar.isDate(_:inSameDayAs:)`). A day picked on the calendar that matches
  no preset shows no chip as selected.
- Log keeps "Tomorrow" as the default, as it is today.
- On Edit, no chip is selected unless the stored date falls on a preset's day
  counted from today.
- The earliest selectable date does not change (start of tomorrow). Every preset is on or after it.
- **Layout:** the chips wrap to a second line when they do not fit, including at
  accessibility text sizes. Labels never truncate.
- **Accessibility:** each chip is a button. The selected chip has the Selected trait.
- **Colors:** chips use the accent (`offshootPrimary`) and follow the theme.

**Files:** new `ReviewDatePreset.swift` (the preset enum) and `ReviewDatePresetRow.swift` (the chip row view),
`LogDecisionView.swift`, `EditDecisionView.swift`.

**Tests:** a unit test that each preset adds the right number of days and keeps the time of day.

---

## Chunk 2 — "So far" trend

`AnalyticsEngine.qualityTrend` returns the trend with a separate flag that says
whether it is provisional. The flag is not a new `QualityTrend` case. Example
shape: `struct TrendResult: Equatable { let trend: QualityTrend; let isSoFar: Bool }`.

Rules, in order:

1. **30-day path (unchanged).** Both 30-day windows have 3 or more marked
   decisions → compare them as today. `isSoFar = false`.
2. **So-far path.** Else, if there are 6 or more marked decisions → sort them by
   `resolvedDate` (oldest first). Split them into an older half and a newer half.
   With an odd count, the newer half gets the extra one. Compare exact-match
   accuracy with the same ±0.1 rule. `isSoFar = true`.
3. **Else** → `.tooEarly`.

Result: with 6 or more marked decisions there is always a trend. `.tooEarly` only
happens below 6.

**Known limit (accepted):** at 6 decisions each half has 3, so its accuracy is
0%, 33%, 67% or 100%. Stable then needs an exact match between halves. Any single
difference reads as Improving or Declining. The "So far" label covers this, and
it only lasts until the 30-day windows fill.

**Dashboard tile (`QuickStatsSection`):** when `isSoFar`, the title reads
"Trend · So far". The value stays Improving, Stable or Declining. VoiceOver reads
"Trend so far, Improving".

**Files:** `AnalyticsEngine.swift`, `QuickStatsSection.swift`, `AnalyticsEngineTests.swift`.

**Tests:**
- 6 marked, all outside the 30-day windows → the so-far path, with the expected trend.
- 7 marked → the newer half has 4.
- Both 30-day windows full → the 30-day path, `isSoFar = false`.
- 5 marked → `.tooEarly`.
- Existing fixtures: `insights-seed-too-early.json` has 3 marked decisions and
  stays `.tooEarly`. `insights-seed.json` fills both windows and stays Improving.
  Update the existing assertions to the new return type only.

---

## Chunk 3 — Starter suggestions

The Dashboard shows a **"Try a quick one"** card while `store.decisions.count < 5`.

Fixed examples, one per category:

| Category | Title |
|---|---|
| Work | Reply to that email today, not Friday |
| Money | Buy the cheaper headphones |
| Health | Skip the gym and rest tonight |
| Relationships | Text an old friend first |
| Home | Leave the dishes until morning |
| Other | Try the new lunch spot |

- The card shows the first 3 examples, in table order, whose title does not match a
  logged decision's title. A used example drops out and the next one takes its
  place. No new stored state.
- A tap switches to the Log tab. The title and category are filled in, and
  "Tomorrow" is selected. The user still picks the expected outcome and taps Save.
- The pre-fill passes through one small shared value owned by `ContentView`
  (for example `@State var logDraft: StarterSuggestion?`), passed to the Dashboard
  and to `LogDecisionView`. The Log view applies it and then clears it.
- Placement: on the Dashboard, below the header card and above Quick Stats.
- The card goes away by itself at 5 decisions.
- **Accessibility:** each suggestion is a button with its title as the label and
  the hint "Fills in the Log form".

**Files:** new `StarterSuggestion.swift` (the examples) and `StarterSuggestionsCard.swift`,
`DashboardView.swift`, `ContentView.swift`, `LogDecisionView.swift`.

**Tests:** a unit test for the filter (logged titles drop out, at most 3 are shown).

---

## Chunk 4 — Post-mark result line and progress copy

Mark Outcome opens only from Decision Detail and returns to it after Save. The
result appears there, and it stays on the decision.

**Result line.** The existing banner in `DecisionDetailView` ("You predicted
correctly!", exact match only) shows for every marked decision. It uses the
first rating (`actual`), as accuracy does.

| First rating vs expected | Line |
|---|---|
| Exact | You predicted correctly! *(unchanged)* |
| 1 step better | Close. It went a little better than you expected. |
| 1 step worse | Close. It went a little worse than you expected. |
| 2+ steps better | It went better than you expected. |
| 2+ steps worse | It went worse than you expected. |

"Better" means `actual.numericValue > expected.numericValue`. Only the exact case
keeps the trophy icon and yellow tint. The other cases use a neutral SF Symbol
and the card color.

**Next-unlock line.** Below the banner, while the user has fewer than 6 marked decisions:
- Fewer than 3: "1 of 3 marked · Optimism unlocks at 3"
- 3 to 5: "4 of 6 marked · Trend unlocks at 6"

**Progress copy:**
- **Trend tile.** `.tooEarly` shows "N of 6 marked" in place of "Too early",
  with the same hourglass icon. The case stays, and only its display text changes.
  `QualityTrend.label` takes the marked count, or the tile builds the text.
- **Optimism card.** "N of 3 marked. Mark M more to see whether you tend to
  expect too much or too little."
- **Cards with 0 marked** (Prediction Accuracy, Outcome Distribution, Outcome
  Trends). The empty text becomes "Mark your first outcome to see this."

**Engine helper.** `AnalyticsEngine` gets one helper, used by the result line:
the signed steps from expected to the first rating (`actual − expected`), or nil
if the decision is not marked. `accuracyBreakdown` and `optimismBias` are left as they are.

**Files:** `DecisionDetailView.swift`, `AnalyticsEngine.swift`,
`QuickStatsSection.swift`, `OptimismCard.swift`, `PredictionAccuracyCard.swift`,
`OutcomeDistributionCard.swift`, `OutcomeTrendCard.swift`, `AnalyticsEngineTests.swift`.

`DecisionDetailView.swift` is 462 lines, near the ~500 soft cap. If this chunk
takes it past 500, extract the outcome card into its own file first (move only),
as the file-granularity rule says.

**Tests:** unit tests for the steps helper (unmarked, exact, ±1, ±2 or more).
The copy is checked on the simulator.

---

## Verification (each chunk)

- Build and unit tests on the iPhone 18 Pro, iOS 27.0 simulator.
- Simulator check with seeded data (`scripts/seed.sh`). Chunk 2 needs a new
  fixture: 6 or more marked decisions, all resolved more than 30 days ago →
  "Trend · So far".
- Dynamic Type check at accessibility-extra-extra-extra-large for the chips, the
  suggestion card and the banner.
- Light and dark mode.

## Docs

- DECISIONS: presets without a same-day option; the "So far" trend and its accepted
  limit; starter suggestions stop at 5 decisions; the result line uses the first rating.
- CHANGELOG and TODO after each chunk.
- README: the Features list (presets, starter suggestions, "So far" trend).
