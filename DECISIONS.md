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

