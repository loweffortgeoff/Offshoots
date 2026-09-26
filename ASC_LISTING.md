# App Store Connect — Current Listing (v2.0.0)

Draft for the 2.0.0 relaunch. Version 1.0.0 was on the App Store before. Bundle ID `com.geoffrey.silva.Offshoots`. App ID 6757363128. Primary locale en-US.

## Subtitle (30 characters max)
Decision Journal & Tracker — 26 characters

Rationale: the app name indexes "offshoots". Apple combines words across the name, the subtitle and the keyword field. "Decision" and "journal" are the two terms people type to find this kind of app. "Tracker" catches "decision tracker". The keyword field does not repeat any of these.

## Promotional Text (170 characters max)
Log a decision, predict how it will go, then record what happened. Revisit it later and see where your predictions land. No account. No ads. No tracking. — 153 characters

## What's New
Offshoots 2.0 is a big update. It keeps going after you decide.

• Revisit any decision later and re-rate it. Every revisit stays on a timeline ("Bad → Good"), and each one can schedule the next check-in.
• Ready to Revisit: due reviews show on the Dashboard and at the top of your Decisions list.
• Pick a review date with one tap: tomorrow, 3 days, 1 week or 1 month.
• New Insights: prediction accuracy with near misses, optimism bias, outcomes by week, and an accuracy trend.
• Each marked decision tells you how the result compared with your prediction.
• Starter suggestions help you log your first decisions.
• Choose Light, Dark or System appearance, and export your data as JSON.
• Larger text and VoiceOver improvements, plus many bug fixes.

Your existing decisions carry over.

## Description
Offshoots — Decide. Predict. Learn.

A decision journal for people who want to get better at deciding. Log a choice, predict how it will turn out, then record what actually happened. Over time, Offshoots shows where your predictions land and where they miss.

Most decision journals stop at the first result. Offshoots keeps going. Revisit a decision weeks or months later and re-rate it, because the outcome you see at 30 days is not always the one you would give at a year. Every revisit is kept on a timeline, so you can see how each decision aged.

Log Decisions in Seconds
A title, a category (Work, Money, Health, Relationships, Home, Other), a stakes level and the outcome you expect. New to this? Tap a starter suggestion to fill in the form.

Follow-Up Reminders
Pick a review date with one tap: tomorrow, 3 days, 1 week or 1 month. A reminder arrives when the decision is ready to review.

Record What Happened
Rate the result from Very Bad to Very Good and add a reflection. Each marked decision tells you how the result compared with your prediction.

Revisit Any Time
Give a decision a new rating and a note on what changed. Schedule the next check-in if you want one. The timeline shows each change ("Bad → Good").

Insights
• Prediction Accuracy: how often your guess matches reality, with near misses shown apart
• Optimism Bias: whether you tend to expect better or worse than what happens
• Outcome Distribution and Outcome Trends by week
• Category Breakdown: where you decide the most
• Accuracy Trend: improving, declining or stable

Prediction accuracy and optimism bias are measured against your first rating, so hindsight cannot inflate them.

Private by design:
• No account, no ads, no analytics, no tracking
• All data stays on your device
• Export everything as JSON
• Light, Dark or System appearance
• Dynamic Type and VoiceOver support
• Optional tip jar. Tips never unlock features.

## Keywords (100 characters max)
choices,predict,outcome,reflect,review,bias,accuracy,insights,revisit,improve,private,free,log,habit — 100 characters

## Keyword Analysis

| Keyword | Purpose |
|---------|---------|
| choices | Synonym for "decisions" (indexed from the subtitle); catches "choice tracker" searches |
| predict | The prediction step is the core mechanic; catches "prediction tracker" searches |
| outcome | Outcome tracking is the second half of the loop |
| reflect | Reflection notes; journaling and self-reflection audience |
| review | Follow-up reminders and Ready to Review |
| bias | Optimism bias card; catches "cognitive bias" browsers |
| accuracy | Prediction accuracy card |
| insights | Insights tab; analytics-minded users |
| revisit | The differentiator: re-rate a decision later |
| improve | Self-improvement searches ("improve decision making") |
| private | Privacy-first pitch; no data collection |
| free | No paywall; all features included |
| log | Short term for logging and tracking |
| habit | Adjacent volume from habit and self-tracking searchers |

**Already indexed by the name and subtitle — deliberately not repeated:** offshoots, decision, journal, tracker.

**Dropped and why:**
- "decisions" (plural): Apple matches plural and singular forms, so "decision" in the subtitle covers it.
- "predictions": "predict" covers it.
- "reminder": low value at 8 characters; the reminder feature is a page-read feature, not a search term.
- "mindful", "stoic": not honest fits. The app is a tracker, not a mindfulness or philosophy app.

**A/B rotation candidates:**
- "habit" ↔ "reminder"
- "log" ↔ "mindful"
- "bias" ↔ "regret" (test whether emotional searches outperform the analytical one)

## Review Notes
See `ReviewNotes.txt` for the In-App Purchase location and product IDs (four consumable tips). Tips do not unlock features.

## Screenshots
The 6.9" set (1320 × 2868 px) comes from `scripts/screenshots.sh`. The first capture pass is in `~/Documents/Dev Workstation/App Images/ASC Screenshots/Offshoots/Captures/2026-09-26/`.

## Notes

- 2026-09-26: First draft, written from README, TODO, CHANGELOG and the audit doc. Version 2.0.0 is a relaunch of the app. The old 1.0.0 was on the App Store. What's New is written as an update from 1.0.0.
- **To do before ship:** the Xcode project still has `MARKETING_VERSION = 1.0`. Set it to 2.0.0. The repo has no release tags.
- **To check:** "Your existing decisions carry over" is true only if the 1.0.0 data file still decodes. The new code defaults missing `stakes` and `revisits`, but test it against a 1.0.0 install before ship.
- **To check:** the feature list in What's New is my reading of the git history (Dec 2025 – Sep 2026), not a diff against the shipped 1.0.0 build. Cut any line that 1.0.0 already had (for example the tip jar, stakes, or the 5-step outcome scale, which are not listed).
- **Not yet done:** no competitor research. Add a Competitor Landscape table (as in `../Task-ed-/ASC_LISTING.md`) before the first keyword refresh, and check the keyword field against real impression data after launch.
- Claims in the description all match shipped features in `README.md`. Recheck "Dynamic Type and VoiceOver support" after the VoiceOver pass on the iPhone 17 Pro (open in TODO).
