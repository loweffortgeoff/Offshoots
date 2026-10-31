# Log a decision

## Sub-features
Title, category menu, notes, stakes, Look Back card for that category, expected outcome, review-date presets and calendar, Save.

## How to get to it (user POV)
Tap the Log tab. Form heading "Log a Decision".

## Driving it with agent-device
1. `V seed screenshots`; `agent-device open com.geoffrey.silva.Offshoots`; snapshot, press `Log`.
2. Snapshot, `fill` the `What decision are you making?` text view with a unique title (for example `Verify run 1`). Screenshot `log-decision-before.png`.
3. Optional: scroll down, with category Work the Look Back card reads "How your past Work decisions went" (seed data has 3 marked Work decisions).
4. Scroll down until `Save Decision` is in the snapshot. Press `Good` (expected outcome). Snapshot again (refs expired), press `Save Decision`, then `agent-device alert accept` if the notification prompt shows.
5. End state: the app jumps to Dashboard, whose counters go 12 to 13 Total and Pending 2 to 3. Screenshot `log-decision-after.png`. Then `V db "Verify run 1"` prints `13 decisions` and the row `| work | medium | expected good | actual None`.

## Gotchas
- Ref expiry: a press using a ref from before the previous action fails with "expired ref frame". Snapshot first.
- `decisions.json` lags the UI by a few seconds; `V db` polls.
- Review date defaults to Tomorrow; a past date is not selectable.
- Do not save in the App Store screenshot flow (see CLAUDE.md); here saving is the point and the sim is disposable.
