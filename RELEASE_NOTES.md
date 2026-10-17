# Release Notes — v2.0.0

**RC:** build 10, accepted on Geoff's phone. **GM target:** around October 24, 2026, tentatively aligned with the Duo release. This is release preparation, not a public-release record.

Theme: Offshoots keeps going after you decide. Revisit decisions as they change, compare your predictions with the results, and use the app across the iPhone Duo's folded and open layouts.

## NEW

- iPhone Duo support: content stays clear of the fold. Dashboard, Log, Decisions and Insights use paired panes in wide landscape and partly open portrait; fully open portrait keeps a readable column. Settings stays in one pane.

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
- Free Look Back on Log: compare every marked decision in the category with its first recorded outcome. Counts and Expected/Turned out bars appear from two decisions; a clear lean can add a headline from five. No purchase or Apple Intelligence is needed.

## IMPROVED

- Insights count your revisits. Good %, Outcomes and Outcome Trends use your latest rating. Accuracy still uses your first rating, so hindsight cannot inflate it.
- The trend appears sooner. After 6 marked decisions it reads "Trend · So far" until the 30-day windows fill.
- Empty Insights cards say what to do next, and the trend tile counts toward 6 marked decisions.
- The app asks for notification permission the first time you set a reminder, not at launch. Reminders also show while the app is open.
- Better contrast in light mode. Dark mode uses the Soil and Loam palette.
- Larger text sizes work across the app. Layouts stack at accessibility sizes instead of breaking words.
- VoiceOver reads chart summaries and outcomes by name. The outcome picker says which rating is selected.
- Edit and Delete are in a context menu on each row.
- The Save button in Mark Outcome and Revisit stays above the keyboard. A tap outside a field closes the keyboard.
- Ratings read Very Bad, Bad, Neutral, Good and Great, with no short forms.
- The welcome splash shows on the first cold launch each day.
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
- Category chart labels are readable in dark mode. Outcome Trends drops date labels that would touch.
- The Log review date refreshes after midnight when the app returns to the foreground.
- Decision titles, stakes choices, outcome badges and revisit rows remain readable at larger text sizes.

## What to Test — 2.0.0

Build 10 device acceptance: Geoff confirmed it looks good on his phone and approved the local merge on 2026-10-17. Keep the checks below as release regression guidance; this report does not mark every older 2.0 check complete.

- Upgrade from 1.0 with existing decisions. Confirm every decision, outcome and reflection loads unchanged.
- Log a decision with the Tomorrow preset. The next day, confirm the reminder arrives and a tap opens the decision.
- Mark an outcome, then revisit it. Confirm the timeline, the result line and the Insights numbers.
- Tap a starter suggestion on a fresh install. Confirm the Log form fills in.
- Export decisions from Settings. Confirm the JSON file opens and holds every decision.
- Switch App Theme between System, Light and Dark while the app runs.
- Import: export from Settings, then import the file. Confirm an empty app imports at once, and an app with decisions asks "Replace N decisions with M from the file?". A file that is not an Offshoots export shows an error.
- Build 10, free Look Back: open Log and pick a category with two or more marked decisions. Counts and bars appear without a tap or purchase. Check with notes and without notes; switch categories and confirm the card updates. Below two marked decisions, check the count-to-go message.
- Build 10, first outcomes: revisit a decision with a different rating. Look Back still compares the prediction with the first outcome. From five decisions, check that a headline appears only for a clear majority. Check Copy, light/dark mode, large text, and VoiceOver.
- Build 10, paid package deferred: no Patterns, generated decision reflection, Clean Up Note, purchase prompt, or Reflection Settings. Personal reflection notes and revisits remain. Confirm on a physical phone before release.

## Historical TestFlight checks — builds 6–9

These record earlier builds. Build 10 supersedes their paid Reflection checks and the old green-launch-screen instruction. The current launch screen uses the app background.

- Build 6, iPhone Duo (iOS 27.1 or later). Closed: the splash screen is centred, and the launch screen is green, not white. Partly open: Dashboard, Log, Insights and Settings sit in one half and keep off the fold. Fully open: they sit in a centred column. In wide landscape, Decisions shows the list and the detail side by side. On any other iPhone, nothing changes.
- Build 6, Insights: on Outcome Trends, the week labels must never touch ("Aug 23Aug 30"). On a phone, every second week is labelled.
- Build 6, Log: leave the Log tab open past midnight, then open the app. The review date must read the new tomorrow, with the Tomorrow chip selected. A date you picked yourself stays.
- Build 7, purchase sheet: tap a locked Reflection control. The sheet opens with "See what your decisions add up to.", an Example card with two bars, and the "Reflection adds" list. The buy button shows the App Store price. Check it in light and dark mode, and at a large text size, where the buttons scroll with the content.
- Build 7, Reflection Depth is back. Build 6 was archived from `main` before the `reflection-depth` merge, so it had none of this. Use a device with Apple Intelligence and decisions that have notes. Look Back: on the Log screen, pick a category with 2 or more marked decisions, tap Look Back, and check that the count line and the Expected and Turned out bars match your decisions. Patterns on Insights: each sentence has a label (Went worse, Went as predicted, Went better), and each should match your notes. Decision reflection: look for the "In other <Category> decisions" section. Log and Edit at large text sizes: the title field wraps and Stakes shows full-width buttons. The "What to Test — TestFlight build 5" list below has the full steps.
- Build 8, splash: the first time you open the app each day, the green splash fades in with the icon and "Welcome to Offshoots". Close the app (swipe it away) and open it again the same day: no splash and no green, straight to the Dashboard. Returning from the background never shows it. The next day it shows once again.
- Build 9, iPhone Duo wide panes: in wide landscape, partly or fully open, Dashboard, Log and Insights use both halves. Dashboard shows the selected decision's detail beside the list (with no tap, the first decision ready for review, else the most recent; it stays on a decision after you mark its outcome). Insights puts Overview, Activity, Categories and Outcomes on the left and Trends, Accuracy, Optimism and Patterns on the right under "Outcomes". Log lists up to 10 recent decisions in the category you are logging (all categories when that one has none), and a tap opens the decision in Decisions. The left pane must reach the split, with no gap. Settings and portrait are unchanged.
- Build 9, iPhone Duo portrait panes: partly open in portrait, Dashboard, Log, Decisions and Insights use both halves, the first pane on top and the second below the fold. The titles in Decisions and Insights are inline and the Log hero is hidden, so the panes keep room for content. Settings stays in the top half. Fully open portrait is unchanged.
- Build 9, other iPhones: nothing changes. On a non-Duo iPhone, check the four tabs in portrait and landscape, and open a marked decision at a large text size: the category, stakes and status row must read normally, with the outcome badge on one line ("Neutral", not "Neu-tral").

## Historical TestFlight checks — build 5

Historical reference only. Build 5 is archived from the `reflection-depth` branch (2026-10-05).

Reflection has more to say in this build. Use a device with Apple Intelligence, and decisions that have notes.

- Look Back (new): on the Log screen, pick a category with 2 or more marked decisions, then tap Look Back. Check that the count line and the Expected and Turned out bars match your decisions. With 5 or more decisions and a clear lean, a headline appears above them. A mixed record shows no headline.
- Patterns on Insights: each sentence now has a label (Went worse, Went as predicted, Went better). Does each sentence match your notes in that group?
- Decision reflection: on a marked decision, look for the new "In other <Category> decisions" section. Does it name the right decisions?
- Tell us if any sentence names a theme your notes do not support, starts with "The notes…" or "All of these…", or gives advice.
- Without the purchase: the Look Back button shows a lock and opens the purchase screen. The purchase screen lists Patterns, the decision reflection and Look Back.
- Log and Edit at large text sizes: the title field has room to wrap, and Stakes shows full-width buttons.

## Review note — 2.0.0

Look Back is free and calculated from recorded predictions and first outcomes. Paid Reflection is disabled in this version. Do not submit the Reflection IAP with 2.0.0. The existing product and purchase work belong to the November 2026 2.1.0 cycle.

## Next cycle — 2.1.0, November 2026

The entire cycle is paid Reflection: accuracy and meaningful connections, real-note evaluation on physical devices, reliable unavailable/error states, honest purchase examples and data requirements, and purchase/Restore validation. Free Look Back stays free. See TODO for the acceptance cases and release gate. November is a target, not a committed release date.

## RC release gates — 2026-10-17

- Build 10 is the accepted RC. The 2026-10-24 GM target is tentative and follows Geoff's Duo release plan; no automatic release is scheduled.
- RC tag `v2.0.0-rc.10` and local/remote main resolve to `62ad837`. The existing `v2.0.0` tag at `86a379e` remains intact.
- ASC: build 10 is uploaded, processed Valid, attached to 2.0.0, and reporting internal/external TestFlight testing. Test instructions were saved and read back. Version 2.0.0 remains Prepare for Submission with manual release; this screenshot pass submitted no review.
- Approved listing copy is saved and verified; Reflection remains a draft outside the 2.0 review setup. Geoff approved the three replacements (Duo 3/4, iPhone Log); promotion and ASC upload are verified Complete with matching checksums/dimensions and original positions. Old files are archived locally.
- The existing duplicate Duo Accuracy image remains in ASC; it was outside the three-image replacement.
- ASC reports the app is removed from sale. Restore the intended App Store availability before GM; availability was left unchanged during TestFlight preparation.
- The phone acceptance closes the general RC device gate. Individual Duo edge-case checks and accepted rotation limits remain recorded in TODO/DECISIONS; no physical Duo test is claimed here.
