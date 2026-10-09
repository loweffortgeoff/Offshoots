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
- Import Decisions in Settings > Data restores an Export file. If the app already holds decisions, it asks before it replaces them.
- Reflection, a one-time unlock, for devices with Apple Intelligence on iOS 26 or later. Patterns on Insights reads what repeats across your decisions. Each marked decision gets a reflection. Clean Up Note fixes spelling and punctuation in a note when you tap it. Everything runs on the device, runs only when you ask, and is never saved. Restore Purchase is in Settings.

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
- Ratings read Very Bad, Bad, Neutral, Good and Great, with no short forms.
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
- Import: export from Settings, then import the file. Confirm an empty app imports at once, and an app with decisions asks "Replace N decisions with M from the file?". A file that is not an Offshoots export shows an error.
- Reflection, on a device with Apple Intelligence (iOS 26 or later). Confirm each surface: Patterns on Insights (needs 5 marked decisions), the reflection on a marked decision, and Clean Up Note on the Log, Mark Outcome and Revisit notes (3 words or more). Confirm the output matches the notes and gives no advice.
- Reflection on a device without Apple Intelligence, or on iOS 18.6 to 25. Confirm Reflection does not show.
- Reflection purchase. The paywall must show the price from the App Store. Try the purchase. TestFlight purchases are free. The purchase screen must say "For testing purposes only. You will not be charged for confirming this purchase." If you do not see that text, do not continue. Send feedback from TestFlight or contact Geoff directly.
- Restore Purchase in Settings, after a reinstall. Confirm Reflection unlocks again.
- Build 6, iPhone Duo (iOS 27.1 or later). Closed: the splash screen is centred, and the launch screen is green, not white. Partly open: Dashboard, Log, Insights and Settings sit in one half and keep off the fold. Fully open: they sit in a centred column. In wide landscape, Decisions shows the list and the detail side by side. On any other iPhone, nothing changes.
- Build 6, Insights: on Outcome Trends, the week labels must never touch ("Aug 23Aug 30"). On a phone, every second week is labelled.
- Build 6, Log: leave the Log tab open past midnight, then open the app. The review date must read the new tomorrow, with the Tomorrow chip selected. A date you picked yourself stays.
- Build 7, purchase sheet: tap a locked Reflection control. The sheet opens with "See what your decisions add up to.", an Example card with two bars, and the "Reflection adds" list. The buy button shows the App Store price. Check it in light and dark mode, and at a large text size, where the buttons scroll with the content.

## Review note

Apple reviews a first in-app purchase together with an app version. Before submission, the product `com.geoffrey.silva.Offshoots.reflection` must be "Ready to Submit" and attached to the version.
