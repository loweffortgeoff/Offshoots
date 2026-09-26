# Offshoots

A personal decision tracking and reflection app for iOS — log decisions, predict outcomes, and learn from the results.

![Platform](https://img.shields.io/badge/platform-iOS%2018.6+-blue)
![Swift](https://img.shields.io/badge/Swift-6-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)

## Overview

Offshoots helps you become a better decision maker. Log your decisions, predict how they'll turn out, then come back later to record the actual outcome. Over time, analytics reveal your patterns — where you're accurate, where you're optimistic, and which categories trip you up.

## Features

- **Decision Logging** — Title, category, stakes level, and expected outcome
- **6 Categories** — Work, Money, Health, Relationships, Home, Other
- **Stakes Levels** — Low, Medium, High
- **Outcome Tracking** — Record actual outcomes: Very Bad, Bad, Neutral, Good, Very Good
- **Follow-Up Reminders** — Scheduled notifications to review past decisions (with smart timing between 7 AM–11 PM)
- **Secondary Follow-Ups** — Option to schedule additional check-ins
- **Reflection Notes** — Add written reflections to any decision

### Analytics & Insights
- **Prediction Accuracy** — How often your guesses match reality, with near misses (one step off) shown apart
- **Optimism Bias** — Whether you tend to expect better or worse than what happens
- **Outcome Distribution** — Positive vs. negative breakdown
- **Category Breakdown** — Which areas you decide on most
- **Trend** — Whether your accuracy is Improving, Declining or Stable over the last 30 days (Too early until there is enough data)
- **Outcome Trends** — Positive, neutral and negative outcomes by week
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

OffshootsTests/                    # Swift Testing: AnalyticsEngine, DecisionStore
docs/fixtures/                     # Seed data for tests and the simulator
scripts/seed.sh                    # Load a fixture into the simulator
```

## Privacy

- No analytics or tracking
- No third-party dependencies
- All data stored locally on device

## Developer

Built by [Low Effort Apps](https://www.loweffortapps.dev)
