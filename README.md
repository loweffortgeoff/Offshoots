# Offshoots

A personal decision tracking and reflection app for iOS — log decisions, predict outcomes, and learn from the results.

![Platform](https://img.shields.io/badge/platform-iOS%2018.6+-blue)
![Swift](https://img.shields.io/badge/Swift-6-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)

## Overview

Offshoots helps you become a better decision maker. Log a decision, predict how it'll turn out, then record what actually happened.

Most decision journals stop there. Offshoots keeps going. Revisit a decision weeks or months later and re-rate it, because the outcome you see at 30 days isn't always the one you'd give at a year. Every revisit is kept as a timeline, so you can see how each decision aged.

Over time, Insights shows your patterns: where your predictions land, where you're optimistic, and which categories trip you up.

## Features

- **Decision Logging** — Title, category, stakes level, and expected outcome
- **6 Categories** — Work, Money, Health, Relationships, Home, Other
- **Stakes Levels** — Low, Medium, High
- **Outcome Tracking** — Record actual outcomes: Very Bad, Bad, Neutral, Good, Very Good
- **Follow-Up Reminders** — Scheduled notifications to review past decisions (with smart timing between 7 AM–11 PM)
- **Review Presets** — Tomorrow, 3 days, 1 week or 1 month, one tap on Log and Edit
- **Starter Suggestions** — Small example decisions for your first few entries
- **Reflection Notes** — Add written reflections to any decision
- **Result Line** — Each marked decision says how the result compared with your prediction, and what unlocks next

### Revisits
- **Re-rate any time.** Give a marked decision a new rating and a note on what changed, as many times as you want.
- **Chained check-ins.** Each revisit can schedule the next one, and a reminder fires when it's due.
- **Revisit timeline.** The decision's detail screen shows every change against the rating it replaced ("Bad → Good").
- **Ready to Revisit.** Due revisits show up on the Dashboard and at the top of the Decisions list, marked with a Revisit pill.
- **Honest accuracy.** Prediction accuracy and optimism bias are measured against your first rating, so later hindsight can't inflate them. Outcome stats (Good %, distribution, trends) use your latest rating.

### Analytics & Insights
- **Prediction Accuracy** — How often your guesses match reality, with near misses (one step off) shown apart (first rating)
- **Optimism Bias** — Whether you tend to expect better or worse than what happens (first rating)
- **Outcome Distribution** — Positive vs. negative breakdown (latest rating)
- **Category Breakdown** — Which areas you decide on most
- **Trend** — Whether your accuracy is Improving, Declining or Stable over the last 30 days (first rating). Before that, from 6 marked decisions, a "So far" trend compares your older and newer decisions
- **Outcome Trends** — Positive, neutral and negative outcomes by week (latest rating)
- **Visual Charts** — Built with the Charts framework

### Navigation
- **Dashboard** — Key stats and recent decisions
- **Log Decision** — Quick entry form
- **Decisions List** — Browse all decisions
- **Insights** — Full analytics dashboard
- **Settings** — Notifications, data overview, JSON export, delete all, app theme (System, Light, Dark), tip jar

## Tech Stack

| Technology | Purpose |
|-----------|---------|
| **SwiftUI** | All UI — views, navigation, charts |
| **Charts** | Analytics visualizations |
| **UserNotifications** | Follow-up reminders |
| **StoreKit** | Tip jar (4 tiers) |
| **Observation** | App state (`@Observable` store) |
| **Combine** | Notification tap routing (`NotificationDelegate` only) |
| **Swift Testing** | Unit tests for `AnalyticsEngine` and `DecisionStore` |

## Project Structure

All app sources sit flat in `Offshoots/`. The groups below are for reading only.

```
Offshoots/
│  # App
├── OffshootsApp.swift             # Entry point, theme, first-launch splash
├── ContentView.swift              # Tab navigation (AppTab)
├── SplashScreenView.swift         # First-launch splash
├── AppTheme.swift                 # System / Light / Dark setting
├── Color+Theme.swift              # Raw palette, outcome colors
│
│  # Model and services
├── Decision.swift                 # Decision, outcome, category, stakes, revisits
├── DecisionStore.swift            # @Observable store, JSON persistence
├── DecisionsExport.swift          # JSON export for the share sheet
├── AnalyticsEngine.swift          # Insights calculations
├── ReminderManager.swift          # Follow-up notification scheduling
├── NotificationDelegate.swift     # Notification tap routing
├── TipJarManager.swift            # StoreKit tip purchases
│
│  # Dashboard
├── DashboardView.swift            # Dashboard screen
├── DashboardHeaderView.swift      # Pending / Completed / Total card
├── ReadyToReviewSection.swift     # Decisions due for review
├── StarterSuggestion.swift        # Starter suggestion model, availability rule
├── StarterSuggestionsSection.swift # Reads the store, shows the card while suggestions remain
├── StarterSuggestionsCard.swift   # "Try a quick one" card for new users
├── QuickStatsSection.swift        # Quick Stats row
├── QuickStatTile.swift            # One Quick Stats tile
├── RecentDecisionsSection.swift   # Recent decisions and empty state
│
│  # Decisions
├── LogDecisionView.swift          # Log a new decision
├── DecisionsListView.swift        # Ready to Review, Upcoming, History
├── DecisionRowView.swift          # One decision row
├── DecisionDetailView.swift       # Full decision details, revisit history
├── EditDecisionView.swift         # Edit a decision
├── MarkOutcomeView.swift          # Record the outcome and a reflection
├── RevisitView.swift              # Re-rate a decision later
├── OutcomePickerView.swift        # Five-step outcome picker
├── OutcomeIcon.swift              # Outcome symbol
├── ReviewDatePreset.swift         # Tomorrow / 3 days / 1 week / 1 month presets
├── ReviewDatePresetRow.swift      # Preset buttons on Log and Edit
├── PredictionResultBanner.swift   # How the first rating compared with the prediction
│
│  # Insights
├── AnalyticsView.swift            # Insights screen, empty state, Decision Activity card
├── CardTitle.swift                # Title row for Insights cards
├── PrimaryCard.swift              # Card container
├── OverallStatsCard.swift         # Overview numbers
├── PredictionAccuracyCard.swift   # Accuracy (correct, close, missed)
├── OptimismCard.swift             # Optimism bias
├── OutcomeDistributionCard.swift  # Outcome ring
├── CategoryBreakdownCard.swift    # Decisions by category
├── OutcomeTrendCard.swift         # Outcomes by week
│
│  # Settings
├── SettingsView.swift             # Settings screen
├── TipJarView.swift               # Tip Jar screen
└── AboutSectionView.swift         # Other Low Effort Apps, About links

OffshootsTests/                    # Swift Testing: AnalyticsEngine, DecisionStore, ReviewDatePreset, StarterSuggestion, PredictionResultBanner
docs/fixtures/                     # Seed data for tests and the simulator
scripts/seed.sh                    # Load a fixture into the simulator
```

## Privacy

- No analytics or tracking
- No third-party dependencies
- All data stored locally on device

## Developer

Built by [Low Effort Apps](https://www.loweffortapps.dev)
