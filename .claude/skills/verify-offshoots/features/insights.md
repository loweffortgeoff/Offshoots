# Insights

## Sub-features
Outcome distribution, trend, category breakdown, prediction accuracy, optimism, Look Back.

## How to get to it (user POV)
Insights tab. Empty data shows "No Data Yet".

## Driving it with agent-device
Seed `screenshots`, press `Insights`, scroll through; snapshot text should include Accuracy and Optimism cards. For exact numbers use `insights-seed` and set the simulator date... only valid 2026-09-25..30 (see CLAUDE.md), so prefer `so-far-trend` (Trend "So far", Improving, date independent). Not yet driven in a proof.

## Gotchas
- Charts' text lives in the accessibility tree as summaries, not axis labels.
- Light/dark switches while running are covered by `agent-device settings appearance dark`.
