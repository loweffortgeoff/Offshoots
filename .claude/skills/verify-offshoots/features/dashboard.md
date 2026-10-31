# Dashboard

## Sub-features
"Your Decisions" counters (Pending, Completed, Total), "Ready to Review" list, Quick Stats (Outcomes % good, Top Category, Trend), starter suggestions when empty.

## How to get to it (user POV)
First tab; the app opens here.

## Driving it with agent-device
Seed `screenshots`, snapshot. Expected texts with that fixture: counters 2 / 10 / 12, "Ready to Review" with 4 rows (for example `Book the dentist, Health • Ready to review, ...`), "Outcomes, 60% good", "Top Category, Work", "Trend so far, Improving". Pressing a row opens that decision's detail. Empty data (fresh install): "Your decisions show here".

## Gotchas
- The fixture is anchored to 2026-09-27; "Ready to Review" depends on today's date versus each follow-up date, so counts can drift. Pending/Completed/Total do not.
