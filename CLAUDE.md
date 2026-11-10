# CLAUDE.md — Offshoots

**This codebase is yours: what it's for and how it's built are your call, and
you'll keep building on it.**

Work like an owner, not a contractor. Decide the structure, fix what you find
in your path, and leave each file in the state you want to come back to. Geoff
sets the product direction and the release calls. The ask-first list in
`~/.claude/CLAUDE.md` (deletes, irreversible steps, uploads, purchases) still
applies.

Offshoots is a SwiftUI decision journal for iPhone: log a decision, predict the
outcome, record the result, revisit it later. `README.md` describes the
features. Current release state is in `CHANGELOG.md` and `TODO.md`, not here.

## Rules that hold

- **iOS 18.6 is the minimum.** The app needs Xcode 27.1 or later to build,
  because the fold APIs are in the iOS 27.1 SDK. Put every 27.1 call behind
  `#available(iOS 27.1, *)`.
- **Hindsight uses no AI model.** Its answers never enter a model prompt
  (DECISIONS 2026-10-28). Free Look Back (`Offshoots/LookBack/`) is calculated,
  not generated, and stays free.
- **Generated Reflection is off.** `ReflectionCenter.paidFeaturesEnabled` is
  false; do not turn it on without Geoff's decision. The DEBUG launch arguments
  run before the flag, so local evaluation works with it off.
  `ReflectionReleaseTests` pins both.
- **Size every Reflection prompt for 4,096 tokens.** That is the on-device
  context on iOS 26; newer simulators report more.
  `theWorstCasePatternsPromptStaysSmall` pins Patterns.
- **Accuracy and optimism use the first recorded outcome.** Outcome statistics
  use the latest rating. A revisit must not change the first group.
- **Fixtures and tests move together.** Tests load `docs/fixtures/*.json` from
  the test bundle, and a new file needs no project change.
  `AnalyticsEngineTests` pins "now" to 2026-09-27. If you change a fixture,
  update the expected values.
- **Do not redeclare an asset color.** Xcode generates a `Color` symbol for each
  color in `Assets.xcassets` (`OutcomeGood` becomes `.outcomeGood`). The same
  name in `Color+Theme.swift` fails the build with "invalid redeclaration".
- **Do not put an always-on tap gesture on a container that holds a graphical
  `DatePicker`.** It takes the day taps. The forms use
  `.gesture(_:including: focused ? .all : .subviews)`.

## Never commit

- `-ReflectionUnlockOnly` enabled in the shared scheme. Every Xcode run would
  start unlocked, and the archive script refuses it.
- `Reflection.storekit` removed from the scheme's Run action.
- A changed default `selectedTab` in `ContentView`, or `-lastSplashDate 0`
  enabled in the scheme.
- The scheme `version` change from 1.7 to 1.3. Xcode makes it when it opens the
  project; it is not Geoff's edit.

## Build and test

One shared scheme, `Offshoots`. Targets: `Offshoots` (the app) and
`OffshootsTests` (Swift Testing, hosted by the app). Bundle ID:
`com.geoffrey.silva.Offshoots`. Leave xcodebuild output verbose; do not add
`-quiet`.

```
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'generic/platform=iOS Simulator' build
```

Tests run on a simulator that this run owns:

```
export RUN_ID="offshoots-$(date +%Y%m%d-%H%M%S)"
V=.claude/skills/verify-offshoots/verify.sh
$V up
SIMULATOR_UDID="$($V sim)"
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination "id=$SIMULATOR_UDID" test
```

Use `id=<UDID>`, not a model name. A test run shuts its simulator down; boot it
again before `simctl` or `scripts/seed.sh`. Unit tests cover logic. For UI
behavior, use the `verify-offshoots` skill.

## Simulators

This project overrides the global iPhone 18 Pro allowlist. Create and use any
compatible iPhone, iPad or Duo simulator without per-session permission, with a
unique `RUN_ID`, and operate only on the UDID recorded for that run. Pick an
installed runtime; fold checks need the Duo and iOS 27.1 or later.

Geoff's active simulator is protected. Never commandeer, erase, shut down or
interact with it. Treat a booted simulator with unclear ownership as his, and
create your own. Never delete a simulator to make a name unambiguous.

Do not wait on real time; seed data. `scripts/seed.sh <fixture>` (with
`SIM=<UDID>`) loads `docs/fixtures/<fixture>.json` as `Documents/decisions.json`
and relaunches. Terminate the app before you write that file by hand, because
the store saves on every change.

## Devices

- **iPhone 17** (`Geoffrey's iPhone`, stable iOS): the device of record for
  dogfooding and any test longer than a day.
- **iPhone 17 Pro** (`Geoff's iPhone`, beta iOS): compile-and-run checks only.
  A fault seen only there can be the beta.

## Release

- `scripts/archive-upload.sh` archives Release and uploads to App Store Connect.
  Bump `CURRENT_PROJECT_VERSION` first. `--archive-only` stops before the
  upload. The upload is outward-facing: run it only when Geoff asks.
- `scripts/screenshots.sh` builds its own Pro Max or Duo simulator and loads a
  date-shifted fixture. Do not save on Log (02) or Revisit (04); run `reload`
  after a stray save.
- Release docs are `RELEASE_NOTES.md` and `ASC_LISTING.md`. The CHANGELOG keeps
  `## In Progress` on top; the release pass moves entries under `## Shipped`.
  Tags are `v<version>`.

## Where to look

| When you work on | Read |
| --- | --- |
| Simulator quirks, taps, StoreKit and sandbox purchases, launch arguments, Insights fixtures, screenshots, the live model harness | `docs/simulator-notes.md` |
| Fold layout, postures and panes (`Offshoots/Fold/`) | `docs/simulator-notes.md`, "iPhone Duo", and the specs in `docs/superpowers/` |
| Driving the app for a proof | `.claude/skills/verify-offshoots/SKILL.md` |
| Why something is the way it is | `DECISIONS.md` |

## Keeping this file short

This file holds rules that stay true. A dated finding ("checked 2026-…", a
tool quirk, an OS behavior) goes in `docs/simulator-notes.md`. Release state
goes in CHANGELOG and TODO. A decision goes in DECISIONS. Markdown is tracked
by default; `.gitignore` covers Xcode user state, build output, PDFs and
`.agents/`.
