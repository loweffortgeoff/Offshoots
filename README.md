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

### Look Back (free)
- On Log, before Expected Outcome: counts and Expected/Turned out bars for every marked decision in the selected category. The comparison uses each first recorded outcome, even after a revisit.
- Needs two marked decisions in the category. Below that, the card says how many remain. From five, a clear majority adds a calculated headline. Results update directly, with Copy and no generation wait.
- Works on iOS 18.6+ without Apple Intelligence, notes, or a purchase.

### Hindsight (one-time purchase)
Record what you would repeat or change during a review or revisit. Review answers and notes across decisions, filtered by answer, outcome or category. Generated Reflection is not included.

### Generated Reflection (dropped)
Dropped on 2026-11-21 (DECISIONS): the on-device and PCC model context limits made it not worth shipping. The code stays in `Offshoots/Reflection/` and is switched off (`ReflectionCenter.paidFeaturesEnabled` is false). Hindsight and free Look Back use no AI model.

### Revisits
- **Re-rate any time.** Give a marked decision a new rating and a note on what changed, as many times as you want.
- **Chained check-ins.** Each revisit can schedule the next one, and a reminder fires when it's due.
- **Revisit timeline.** The decision's detail screen shows every change against the rating it replaced ("Bad → Good").
- **Ready to Revisit.** Due revisits show up on the Dashboard and at the top of the Decisions list, marked with a Revisit pill.
- **Honest accuracy.** Prediction accuracy and optimism bias are measured against your first rating, so later hindsight can't inflate them. Outcome stats (Good %, distribution, trends) use your latest rating.

### Analytics & Insights
- **Prediction Accuracy** — How often your guesses match reality, with near misses (one step off) shown apart (first rating)
- **Optimism Bias** — Whether you tend to expect better or worse than what happens, with worse/as-predicted/better counts (first rating). Small average gaps show “No overall lean” when misses remain.
- **Outcome Distribution** — Positive vs. negative breakdown (latest rating)
- **Category Breakdown** — Which areas you decide on most
- **Trend** — Whether your accuracy is Improving, Declining or Stable over the last 30 days (first rating). Before that, from 6 marked decisions, a "So far" trend compares your older and newer decisions
- **Outcome Trends** — Positive, neutral and negative outcomes by week (latest rating)
- **Visual Charts** — Built with the Charts framework

### Widgets & Controls
- **Medium Home Screen widget** — Decisions ready to review (titles hidden while the phone is locked), with links to log a decision or open Hindsight. People who have not bought Hindsight get the purchase sheet.
- **Small Home Screen widget** — How many decisions are ready to review.
- **Lock Screen widgets** — Circular (count or checkmark), inline (count or next review date), and rectangular (soonest due title hidden while locked, plus "+ N more" or next due date).
- **Control Center control** — "Log a Decision" button (`ControlWidgetButton`) that opens Offshoots straight to the Log tab from Control Center, a Lock Screen corner button, or the Action Button.
- Widgets read a small summary (titles and dates only) from an App Group. Notes and Hindsight answers never leave the app.

### Siri, Shortcuts & Spotlight
- **Actions** — Log a Decision, Record Outcome (first outcome or a revisit), Show Decisions Ready to Review, Open Decision, Open Ready to Review. Every action needs an unlocked phone.
- **Siri phrases** — work with no setup: "Log a decision in Offshoots", "Add a decision in Offshoots", "Record an outcome in Offshoots", "Review a decision in Offshoots", "Show decisions ready to review in Offshoots", "What decisions are ready to review in Offshoots".
- **Spotlight** — finds decisions by title and opens the exact decision.
- **Siri Suggestions** — logging, marking or revisiting in the app donates the action with only its category, stakes or outcome.
- Notes, reflections, revisit notes and Hindsight answers never reach Siri, Shortcuts, Spotlight or donations. No App Intent schema is adopted (DECISIONS 2026-11-21).

### Navigation
- **Dashboard** — Key stats and recent decisions
- **Log Decision** — Quick entry form
- **Decisions List** — Browse all decisions
- **Insights** — Full analytics dashboard
- **Settings** — Notifications, data overview, JSON export and import, delete all, app theme (System, Light, Dark)

## Tech Stack

| Technology | Purpose |
|-----------|---------|
| **SwiftUI** | All UI — views, navigation, charts |
| **Charts** | Analytics visualizations |
| **UserNotifications** | Follow-up reminders |
| **FoundationModels** | Used only by the dropped generated Reflection code, which is switched off |
| **StoreKit** | Hindsight one-time purchase and Restore |
| **Observation** | App state (`@Observable` store) |
| **Combine** | Notification and link routing (`NotificationDelegate` only) |
| **WidgetKit** | Medium and small Home Screen widgets, Lock Screen accessory widgets, and Control Center control (`OffshootsWidgets` extension) |
| **AppIntents** | Siri and Shortcuts actions, `DecisionEntity`, App Shortcuts phrases, donations; plus the internal non-discoverable `OpenLogDecisionIntent` for the Control Center control |
| **CoreSpotlight** | Indexes `DecisionEntity` (title, category, outcomes; never notes) |
| **ReservedRegion, ArrangementView** | iPhone Duo fold layout (iOS 27.1 SDK, behind `#available`) |
| **Swift Testing** | Unit tests for `AnalyticsEngine`, `ChartSummary`, `DecisionStore`, `FoldPosture`, `DashboardSelection`, `DecisionsSelection`, `LogRecentList`, `ReviewDatePreset`, `StarterSuggestion`, `PredictionResultBanner`, `SplashSchedule`, `LookBackStats`, Hindsight (access, capture, data, review, summary, StoreKit), `AppRoute`, `WidgetSummary` and its writer, the Shortcuts service, entity, intents and Spotlight indexer, the Reflection policy (gate, eligibility, digest, prompts, entitlement), and the screenshot and Reflection notes fixtures. `ReflectionLiveOutputTests` runs the real on-device model and is off unless `REFLECTION_LIVE=1` (see `docs/superpowers/archive/2026-10-05-reflection-depth.md`) |

## Project Structure

App sources sit in `Offshoots/`, with LookBack, Hindsight, Reflection, Shortcuts and Fold feature folders.

```
Offshoots/
│  # App
├── OffshootsApp.swift             # Entry point, theme, first-launch splash
├── ContentView.swift              # Tab navigation (AppTab)
├── SplashScreenView.swift         # First-launch splash
├── SplashSchedule.swift           # Splash on the first cold launch of each day
├── AppTheme.swift                 # System / Light / Dark setting
├── Color+Theme.swift              # Raw palette, outcome colors
│
│  # Model and services
├── Decision.swift                 # Decision, outcome, category, stakes, revisits
├── DecisionStore.swift            # @Observable store, JSON persistence
├── DecisionsExport.swift          # JSON export for the share sheet
├── DecisionsImport.swift          # Restore an Export file
├── AnalyticsEngine.swift          # Insights calculations
├── ReminderManager.swift          # Follow-up notification scheduling
├── NotificationDelegate.swift     # Holds the pending route from a reminder tap or link
├── AppRoute+App.swift             # Decision and Hindsight route targets
├── WidgetSummary+Decisions.swift  # Builds the widget summary from the journal
├── WidgetSummaryWriter.swift      # Writes the summary to the App Group, reloads widgets
│
│  # Dashboard
├── DashboardView.swift            # Dashboard screen
├── DashboardSelection.swift       # Which decision the Duo detail pane shows
├── DashboardRowSelection.swift    # Row behavior beside a Duo detail pane
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
├── StakesPickerView.swift         # Stakes control, scaled choices at accessibility sizes
├── LogRecentList.swift            # Which recent decisions the Duo Log pane lists
├── LogRecentPane.swift            # Recent decisions beside the Log form (Duo)
├── DecisionsListView.swift        # Ready to Review, Upcoming, History
├── DecisionsSplitView.swift       # List and detail side by side in wide landscape (iPhone Duo)
├── DecisionsSelection.swift       # Which decision the detail pane shows
├── DecisionRowView.swift          # One decision row
├── DecisionDetailView.swift       # Full decision details, revisit history
├── RevisitHistoryCard.swift       # Revisit timeline on the detail screen
├── EditDecisionView.swift         # Edit a decision
├── MarkOutcomeView.swift          # Record the outcome and a reflection
├── RevisitView.swift              # Re-rate a decision later
├── OutcomePickerView.swift        # Five-step outcome picker
├── OutcomeIcon.swift              # Outcome symbol
├── ReviewDatePreset.swift         # Tomorrow / 3 days / 1 week / 1 month presets
├── ReviewDatePresetRow.swift      # Preset buttons on Log and Edit
├── PredictionResultBanner.swift   # How the first rating compared with the prediction
│
│  # Siri, Shortcuts and Spotlight (Shortcuts/ folder)
├── Shortcuts/                     # ShortcutsService, DecisionEntity and query, AppEnums, intents, OffshootsShortcuts, Spotlight indexer, donations
│
│  # iPhone Duo fold layout (Fold/ folder)
├── Fold/                          # FoldRegion, FoldLayout, FoldPosture, FoldPostureReader, FoldPane, TwoPaneReader, WidePanes
│
│  # Insights
├── AnalyticsView.swift            # Insights screen, empty state, Decision Activity card
├── ChartSummary.swift             # VoiceOver summaries for the charts
├── CardTitle.swift                # Title row for Insights cards
├── PrimaryCard.swift              # Card container
├── OverallStatsCard.swift         # Overview numbers
├── PredictionAccuracyCard.swift   # Accuracy (correct, close, missed)
├── OptimismCard.swift             # Optimism bias
├── OutcomeDistributionCard.swift  # Outcome ring
├── CategoryBreakdownCard.swift    # Decisions by category
├── OutcomeTrendCard.swift         # Outcomes by week
│
│  # Free Look Back, Hindsight and dropped Reflection
├── LookBack/                      # Free card, statistics and comparison bars
├── Hindsight/                     # Check-in answers, review, filters, purchase sheet and Settings section
├── Reflection/                    # Dropped generated Reflection (switched off); shared entitlement and purchase code
│
│  # Settings
├── SettingsView.swift             # Settings screen
├── SettingsDataSection.swift      # Export, import and Delete All
└── AboutSectionView.swift         # Other Low Effort Apps, About links

Shared/                            # In the app and the widget extension: AppRoute, AppRouteDispatcher, LockScreenPresentation, OpenLogDecisionIntent, WidgetSummary (with the DueDay rule)
OffshootsWidgets/                  # WidgetKit extension: Home Screen widgets, Lock Screen widgets, Control Center control, timeline provider
OffshootsTests/                    # Swift Testing: AnalyticsEngine, ChartSummary, DecisionStore, FoldPosture, DashboardSelection, DecisionsSelection, LogRecentList, ReviewDatePreset, StarterSuggestion, PredictionResultBanner, SplashSchedule, LookBackStats, Hindsight, AppRoute, WidgetSummary, LockScreenAndControl, ShortcutsService, DecisionEntity, ShortcutsIntent, DecisionSpotlightIndexer, Reflection policy, screenshot fixture
Reflection.storekit                # Local StoreKit test product; Hindsight on the existing product ID
docs/fixtures/                     # Seed data for tests and the simulator
scripts/seed.sh                    # Load a fixture into the simulator
scripts/screenshots.sh             # App Store capture setup on the iPhone 18 Pro Max
scripts/archive-upload.sh          # Archive Release and upload to TestFlight (--archive-only to stop before upload)
```

The app needs **Xcode 27.1 or later** (iOS 27.1 SDK) to build. It still supports iOS 18.6 at runtime. See `docs/simulator-notes.md`, "iPhone Duo (fold layout)".

## Privacy

- No analytics or tracking
- No third-party dependencies
- All data stored locally on device

## Developer

Built by [Low Effort Apps](https://www.loweffortapps.dev)
