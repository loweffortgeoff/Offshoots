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

```
Offshoots/
├── OffshootsApp.swift          # App entry point
├── ContentView.swift           # Tab navigation
├── DashboardView.swift         # Stats overview
├── DecisionDetailView.swift    # Full decision details
├── EditDecisionView.swift      # Edit existing decisions
├── MarkOutcomeView.swift       # Record outcomes & reflections
├── SettingsView.swift          # App settings
├── AnalyticsEngine.swift       # Insights calculations
├── DecisionStore.swift         # Data persistence (JSON)
├── ReminderManager.swift       # Notification scheduling
├── TipJarManager.swift         # StoreKit purchases
└── SplashView.swift            # Launch animation
```

## Privacy

- No analytics or tracking
- No third-party dependencies
- All data stored locally on device

## Developer

Built by [Low Effort Apps](https://www.loweffortapps.dev)
