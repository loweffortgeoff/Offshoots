# App Store Connect — Current Listing (v2.0.0)

Listing for the 2.0.0 relaunch. Version 1.0.0 was on the App Store before. Bundle ID `com.geoffrey.silva.Offshoots`. App ID 6757363128. Primary locale en-US.

## Subtitle (30 characters max)
Decision Journal & Predictions — 30 characters

Rationale: the app name indexes "offshoots". Apple combines words across the name, the subtitle and the keyword field. "Decision" and "journal" are the two terms people type to find this kind of app. "Predictions" replaces "Tracker": prediction trackers (Foresee, ClaimCheck, Prediction Tracker & Journal) are their own search niche, and the prediction step is what sets Offshoots apart from a plain decision journal. "Tracker" moves to the keyword field, where it still combines with "decision" and "prediction". It still reads as a subtitle, not a list.

## Promotional Text (170 characters max)
Predict how a decision will turn out, record what happened, then revisit it months later. Insights show where your predictions land and where optimism gets ahead of you. — 169 characters

## What's New
Offshoots 2.0 is a big update. It keeps going after you decide.

• Revisit any decision later and re-rate it. Every revisit stays on a timeline ("Bad → Good"), and each one can schedule the next check-in.
• Ready to Review: due reviews show on the Dashboard and at the top of your Decisions list.
• Pick a review date with one tap: tomorrow, 3 days, 1 week or 1 month.
• Insights: near misses in Prediction Accuracy, a new Optimism card, and stats that count your revisits.
• Each marked decision tells you how the result compared with your prediction.
• Starter suggestions help you log your first decisions.
• Choose Light, Dark or System appearance, and export your data as JSON.
• Larger text and VoiceOver improvements, plus many bug fixes.

## Description
Offshoots — Decide. Predict. Learn.

A decision journal for people who want to get better at deciding. Log a choice, predict how it will turn out, then record what actually happened. Over time, Offshoots shows where your predictions land and where they miss.

Most decision journals stop at the first result. Offshoots keeps going. Revisit a decision weeks or months later and re-rate it, because the outcome you see at 30 days is not always the one you would give at a year. Every revisit is kept on a timeline, so you can see how each decision aged.

Log Decisions in Seconds
A title, a category (Work, Money, Health, Relationships, Home, Other), a stakes level and the outcome you expect. New to this? Tap a starter suggestion to fill in the form.

Follow-Up Reminders
Pick a review date with one tap: tomorrow, 3 days, 1 week or 1 month. A reminder arrives when the decision is ready to review.

Record What Happened
Rate the result from Very Bad to Great and add a reflection. Each marked decision tells you how the result compared with your prediction.

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

## Keywords (100 characters max)
tracker,choice,outcome,forecast,regret,bias,review,reflect,accuracy,revisit,log,diary,improve,learn — 99 characters

## Competitor Landscape
| App | Keyword Themes |
| --- | --- |
| Decision Journal (decisionjournalapp.com) | decision journal, make better decisions, document, review, analyze |
| Decision Journal - Pros & Cons | pros and cons, compare options, weighted criteria, verdict, decision journal |
| Decision Receipt | review choices, reduce regret, outcome tracking, reflection, review dates |
| Foresee: Predictions Tracker | predictions tracker, confidence, accuracy, reveal date, calibration |
| ClaimCheck: Prediction Tracker | prediction tracker, bets, challenges, outcomes, proven or false |

Two clusters: decision journals (log and review) and prediction trackers (forecast and score). Offshoots sits between them. None of them re-rate a decision over time, so "revisit" is uncontested.

## Keyword Analysis

| Keyword | Purpose |
|---------|---------|
| tracker | Moved from the subtitle; builds "decision tracker" and "prediction tracker" |
| choice | Synonym for "decision"; Decision Receipt uses "choices" in its subtitle |
| outcome | Outcome tracking is the second half of the loop; "outcome tracker" |
| forecast | Prediction-tracker synonym; "forecast journal", "forecast tracker" |
| regret | Emotional search angle ("reduce regret", "regret"); Decision Receipt targets it |
| bias | Optimism bias card; "cognitive bias" searches |
| review | Follow-up reminders and Ready to Review; "decision review" |
| reflect | Reflection notes; self-reflection searches |
| accuracy | Prediction accuracy card; "prediction accuracy" |
| revisit | The differentiator: re-rate a decision later |
| log | Short term; "decision log", "prediction log" |
| diary | Journal synonym with its own search volume; "decision diary" |
| improve | "improve decision making" searches |
| learn | "learn from mistakes", "learn from decisions" |

**Already indexed by the name and subtitle, so not repeated:** offshoots, decision, journal, prediction(s).

**Dropped and why:**
- "predict": the subtitle now carries "predictions".
- "private": privacy is not the pitch. The app's substance is the predict, record, revisit loop.
- "free": low intent, and it says nothing about what the app does.
- "insights": generic. Every analytics app uses it.
- "habit": weak fit. Offshoots is not a habit tracker, so those searchers bounce.
- "pros", "cons", "decide": the pros-and-cons crowd wants a decision helper before the choice. Offshoots works after the choice.
- "calibration": fits the prediction niche, but few people type it.

**A/B rotation candidates:**
- "learn" ↔ "mistake"
- "diary" ↔ "calibrate"
- "regret" ↔ "hindsight"

## Screenshots
The 6.9" set (1320 × 2868 px) comes from `scripts/screenshots.sh`. The first capture pass is in `~/Documents/Dev Workstation/App Images/ASC Screenshots/Offshoots/Captures/2026-09-26/`.

## Notes

- 2026-09-26: First draft, written from README, TODO, CHANGELOG and the audit doc. Version 2.0.0 is a relaunch of the app. The old 1.0.0 was on the App Store. What's New is written as an update from 1.0.0.
- 2026-09-26 (release pass): `MARKETING_VERSION` is 2.0.0, build 1. The 2.0.0 baseline is every commit after `0e29c15`, the 1.0 upload (2026-01-04; released 2026-01-12). What's New was checked against the 1.0 source (`AnalyticsView.swift` is the same at `0e29c15` and `8ed7dac`): 1.0 already had Prediction Accuracy, Outcome Distribution, Outcome Trends, Category Breakdown and the Trend tile, so the Insights line names only what is new (near misses, the Optimism card, revisit-aware stats).
- Claims in the description all match shipped features in `README.md`. The VoiceOver pass on the iPhone 17 is done (TODO), so "Dynamic Type and VoiceOver support" stands.
- 2026-09-26 (ASO pass): Competitor scan done. Subtitle is now "Decision Journal & Predictions" to reach the prediction-tracker niche. Keywords rebuilt, and "private" and "free" are out. The promo text no longer leans on privacy. Check impressions for "prediction tracker" and "decision tracker" after launch. Recheck "revisit" against competitors at the next refresh, since it is uncontested for now.
- `RELEASE_NOTES.md` starts with 2.0.0. The next ASO refresh diffs against the `v2.0.0` tag.
