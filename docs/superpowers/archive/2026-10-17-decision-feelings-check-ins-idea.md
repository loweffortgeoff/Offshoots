# Decision Feelings Check-ins — Idea for Future Consideration

Status: **Idea only. Not approved for implementation.**
Date: 2026-10-17

## Summary

Explore adding an optional way to record how a decision feels, separately from how well it turns out. This would adapt the useful distinction in Contrition into Offshoots without importing a second decision-tracking loop.

## User problem

A decision can have a good outcome and still feel wrong, or feel uncertain at first and later feel settled. Offshoots records expected and actual outcomes, but those ratings do not capture how the person feels about the choice itself.

## Product intent

Help users notice the difference between outcome quality and personal confidence or regret over time. Keep outcome tracking and prediction accuracy as the core Offshoots loop.

## Possible experience

- When logging a decision, the user may record an initial feeling, such as confident, unsure, or taking a leap.
- During an existing review or revisit, the user may record how the decision feels now, such as still good, nagging, or something they would undo.
- The decision timeline may show these entries beside the existing outcome history.
- Insights may summarize feeling changes separately from outcome quality and prediction accuracy.

All entries would be optional. Skipping them would leave the current logging and review flows intact.

## Product boundaries

- Keep the existing five-point expected and actual outcome ratings unchanged.
- Do not treat sentiment as an outcome rating or include it in prediction accuracy, optimism bias, or outcome charts.
- Do not add a separate check-in schedule. Reuse existing review and revisit moments if this idea proceeds.
- Do not add a new tab or a second journal.
- Do not require a feeling entry to save, review, revisit, or resolve a decision.
- Do not port Contrition's SwiftData/CloudKit store, widget, App Intents, navigation, or Reflection implementation as part of this idea.
- Do not assume a purchase or Reflection dependency.

## Reuse potential

Contrition's initial sentiment choices, check-in sentiment choices, and drift classification are useful references. They need product and data-model adaptation before reuse. Its persistence, scheduling, and system integrations are specific to Contrition and are not direct port candidates.

## Open questions

- Does recording feelings add enough value to justify another choice during logging or review?
- Should feelings be captured only at the first outcome review, or at every revisit?
- Should the initial and later scales use labels, a simple positive/unsure/negative choice, or another model?
- What does “resolve” mean if outcome tracking is complete but the user still feels uneasy?
- Would a small timeline signal be useful without adding a new analytics card?
- Should existing decisions remain sentiment-free, with no backfill prompt?

## Success signals to evaluate before implementation

- Users can explain the difference between “How did it turn out?” and “How do you feel about the decision now?”
- The optional check-in does not make logging or revisiting feel burdensome.
- The resulting history reveals a useful pattern that outcome ratings alone do not show.

## Decision gate

Do not implement from this note alone. Revisit the idea during a future Offshoots planning session. If approved, define the smallest testable slice and its data, migration, accessibility, and analytics boundaries before coding.
