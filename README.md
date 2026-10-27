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

### Paid feature direction (2.1.0 design approved)
The approved design is [Hindsight check-ins](docs/superpowers/specs/2026-10-24-hindsight-check-ins-design.md): record what you would repeat or change, then review answers and their notes across decisions. Filter the review by answer, outcome, and current category. Phone and paid-value acceptance remain open; production capture and purchase remain disabled. See [Hindsight evaluation](docs/hindsight-evaluation.md) for evidence and open acceptance gates. Generated Reflection is outside the proposed purchase promise.

### Generated Reflection (retained; activation blocked)
Paid Reflection is dormant in 2.0. The earlier approved 2.1.0 design proposed evidence-linked Patterns across categories and readings of how a decision aged, generated on request and saved as dated history. Clean Up Note was part of that proposal; free Look Back stays free. See the [approved design](docs/superpowers/specs/2026-10-24-paid-reflection-design.md), [implementation plan](docs/superpowers/plans/2026-10-24-paid-reflection.md), and TODO. Local engineering checks pass, but generated-text quality fails the release gate. `ReflectionCenter.paidFeaturesEnabled` remains false. See [evaluation status](docs/reflection-evaluation.md) for scored cases and the remaining real-note/device gates.

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
| **FoundationModels** | Retained for 2.1.0; production Reflection is disabled in 2.0 |
| **StoreKit** | Retained for 2.1.0; purchase setup is skipped in 2.0 |
| **Observation** | App state (`@Observable` store) |
| **Combine** | Notification tap routing (`NotificationDelegate` only) |
| **ReservedRegion, ArrangementView** | iPhone Duo fold layout (iOS 27.1 SDK, behind `#available`) |
| **Swift Testing** | Unit tests for `AnalyticsEngine`, `DecisionStore`, `FoldPosture`, `DecisionsSelection`, `ReviewDatePreset`, `StarterSuggestion`, `PredictionResultBanner`, the Reflection policy (gate, eligibility, digest, prompts, entitlement), and the screenshot and Reflection notes fixtures. `ReflectionLiveOutputTests` runs the real on-device model and is off unless `REFLECTION_LIVE=1` (see `docs/superpowers/archive/2026-10-05-reflection-depth.md`) |

## Project Structure

App sources sit in `Offshoots/`, with LookBack, Reflection and Fold feature folders.

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
├── DecisionsImport.swift          # Restore an Export file
├── AnalyticsEngine.swift          # Insights calculations
├── ReminderManager.swift          # Follow-up notification scheduling
├── NotificationDelegate.swift     # Notification tap routing
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
│  # iPhone Duo fold layout (Fold/ folder)
├── Fold/                          # FoldRegion, FoldLayout, FoldPosture, FoldPostureReader, FoldPane
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
│  # Free Look Back and deferred Reflection
├── LookBack/                      # Free card, statistics and comparison bars
├── Reflection/                    # Deferred 2.1.0 policy, generators, paid cards, note cleanup and purchase UI
│
│  # Settings
├── SettingsView.swift             # Settings screen
└── AboutSectionView.swift         # Other Low Effort Apps, About links

OffshootsTests/                    # Swift Testing: AnalyticsEngine, DecisionStore, FoldPosture, DecisionsSelection, ReviewDatePreset, StarterSuggestion, PredictionResultBanner, Reflection policy, screenshot fixture
Reflection.storekit                # Local StoreKit test product; Hindsight on the existing product ID
docs/fixtures/                     # Seed data for tests and the simulator
scripts/seed.sh                    # Load a fixture into the simulator
scripts/screenshots.sh             # App Store capture setup on the iPhone 18 Pro Max
scripts/archive-upload.sh          # Archive Release and upload to TestFlight (--archive-only to stop before upload)
```

The app needs **Xcode 27.1 or later** (iOS 27.1 SDK) to build, on the Mac mini. It still supports iOS 18.6 at runtime. See `CLAUDE.md`, "iPhone Duo (fold layout)".

## Privacy

- No analytics or tracking
- No third-party dependencies
- All data stored locally on device

## Developer

Built by [Low Effort Apps](https://www.loweffortapps.dev)
