# Release Notes — v2.0.0

Theme: Offshoots keeps going after you decide. 1.0 stopped at the first result. 2.0 lets you revisit a decision, shows what each result means, and gets a new user to useful Insights sooner.

## NEW

- Revisit any marked decision and re-rate it. Add a note on what changed and schedule the next check-in. A timeline shows each change ("Bad → Good").
- Ready to Review: due decisions show on the Dashboard and at the top of the Decisions list, with a Review or Revisit pill.
- Review-date presets on Log and Edit: Tomorrow, 3 days, 1 week or 1 month.
- Each marked decision shows how the result compared with your prediction, and what unlocks next while you have fewer than 6 marked.
- Starter suggestions on the Dashboard fill in the Log form for your first decisions.
- An Optimism card on Insights shows whether you expect better or worse than what happens.
- Prediction Accuracy shows near misses (one step off) apart from misses.
- A Notes field on the Log screen.
- App Theme in Settings: System, Light or Dark.
- Export your decisions as JSON, or delete them all (with a confirmation).

## IMPROVED

- Insights count your revisits. Good %, Outcomes and Outcome Trends use your latest rating. Accuracy still uses your first rating, so hindsight cannot inflate it.
- The trend appears sooner. After 6 marked decisions it reads "Trend · So far" until the 30-day windows fill.
- Empty Insights cards say what to do next, and the trend tile counts toward 6 marked decisions.
- The app asks for notification permission the first time you set a reminder, not at launch. Reminders also show while the app is open.
- Better contrast in light mode. Dark mode uses the Soil and Loam palette.
- Larger text sizes work across the app. Layouts stack at accessibility sizes instead of breaking words.
- VoiceOver reads outcomes by name, and the outcome picker says which one is selected.
- Edit and Delete are in a context menu on each row.
- The Save button in Mark Outcome and Revisit stays above the keyboard. A tap outside a field closes the keyboard.
- The welcome splash shows on the first launch only.
- Settings is simpler: the Tip Jar is gone.

## FIXED

- The detail screen shows edits and outcomes at once.
- Tapping a reminder opens the right decision.
- The Follow-up Reminders toggle cancels reminders when off and restores them when on.
- An unreadable data file is saved aside before the app can overwrite it.
- You can no longer pick a review date in the past.
- "See All" opens the Decisions tab.
- Completed rows show the date you marked the outcome.
- Insights group outcomes by the week you marked them, not the week you logged the decision.
- The trend no longer shows "Stable" when there is too little data, and Top Category shows "Tied" on a tie.
- Outcome percentages add up to 100.
- Category chart labels are readable in dark mode.

## What to Test — 2.0.0

- Upgrade from 1.0 with existing decisions. Confirm every decision, outcome and reflection loads unchanged.
- Log a decision with the Tomorrow preset. The next day, confirm the reminder arrives and a tap opens the decision.
- Mark an outcome, then revisit it. Confirm the timeline, the result line and the Insights numbers.
- Tap a starter suggestion on a fresh install. Confirm the Log form fills in.
- Export decisions from Settings. Confirm the JSON file opens and holds every decision.
- Switch App Theme between System, Light and Dark while the app runs.
