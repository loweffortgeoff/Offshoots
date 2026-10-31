---
name: verify-offshoots
description: Build and drive the Offshoots iOS app (SwiftUI decision journal, bundle com.geoffrey.silva.Offshoots) on a throwaway iOS Simulator to prove a change works as a user would see it. Use after UI or store changes, or when asked to "test on the simulator" or "verify" Offshoots.
---

# Verify Offshoots

Surface: iPhone app, five tabs (Dashboard, Log, Decisions, Insights, Settings). Data is one file, `Documents/decisions.json`, so every proof checks the screen and that file. Project facts (fixtures, launch args, simulator quirks) live in `CLAUDE.md`; read its "Simulator Testing" section if something odd happens.

Everything below uses `.claude/skills/verify-offshoots/verify.sh` (call it `V`). Its state is in `/tmp/offshoots-verify`.

## Launch
1. `V up` builds Debug with Xcode 27.x (`/Applications/Xcode.app`), creates a **new** simulator `verify-offshoots-HHMMSS` (iPhone 18 Pro, iOS 27.2) and installs. Prints `READY sim=...`. First build is about 3 min. It starts from an empty data folder; the app launches with no decisions.
2. `V seed screenshots` loads 12 decisions (4 "Ready to Review") and relaunches with the splash skipped. Other fixtures: `ls docs/fixtures`. `insights-seed` fills Insights only when today is 2026-09-25..30; `so-far-trend` and `screenshots` do not depend on the date.
3. Open the simulator for driving: call the T3 `device_list` then `device_open` (deviceId from `/tmp/offshoots-verify/sim`, hostId `local`). It returns an `agent-device` command; use it for every tap, fill, scroll and screenshot. Without T3 tools, use the Xcode `DeviceInteractionStartSession` tools (see `device-verification-xcode27`). Then `agent-device open com.geoffrey.silva.Offshoots` (add `--relaunch` only if you want a fresh start; it keeps the seeded data).

Ready means the Dashboard snapshot shows "Your Decisions". Do not tap during the 2 s splash (seed skips it).

## Doctor
`V doctor` (read-only): simulator booted, app installed, built commit vs HEAD, app running. If it warns about uncommitted app changes, run `V up` again (it reuses the simulator and reinstalls; the app's data is kept unless you reseed).

## Drive
- `agent-device snapshot -i` gives `@eN` refs with labels. **Refs expire after any action**: snapshot again before each press/fill.
- Handles are accessibility labels: tab buttons `Dashboard|Log|Decisions|Insights|Settings`; Log fields `What decision are you making?` (fill), `Category, Work` (menu), `Low|Medium|High`, outcome buttons `Very Bad|Bad|Neutral|Good|Great`, `Save Decision`. Decision rows are buttons labelled `<title>, <Category> • ...`.
- Scroll with `agent-device scroll down`. Content below the fold is not in the snapshot until scrolled into view. `fill` leaves the keyboard up, but scrolling down the form reaches the lower controls (checked 2026-10-31).
- The first save asks for notification permission: `agent-device alert accept`.
- Debug-only launch args (type the dash): `-ReflectionFake`, `-ReflectionUnlockOnly`, `-HindsightStoreKit`. They are not needed for the features in `features/`. Paid Reflection is off in 2.0/2.1 builds.
- Feature walkthroughs: `features/README.md`.

## Evidence
Save to `/tmp/offshoots-verify/evidence/<feature>-<step>.png` with `agent-device screenshot <path>` (1x points; add `--pixel-density 3` for full res). Per proof capture: the screen before the action, the screen after, and `V db "<title>"` output. Standards:
- Use the real UI path. Do not edit `decisions.json` to create the state you are testing; seeding fixtures before the run is fine.
- The store writes `decisions.json` a few seconds after the UI changes, so `V db <title>` polls up to 20 s. A missing row after that is a failure.
- A UI change with no matching file change (or the reverse) is a bug, not noise.
- A saved decision schedules a local notification; that is the only external side effect, and it stays on the simulator.

## Isolation
`V up` always uses its own simulator. Never boot, reuse or erase the user's `iPhone 18 Pro`, `iPhone Duo` or other `verify-*` simulators, and do not run two proofs in one `/tmp/offshoots-verify`. Tests (`xcodebuild test`) shut simulators down, so do not run them mid-proof.

## Cleanup
Close the T3 device with `device_close` (shutdown true). Then `V down` deletes the throwaway simulator only; `/tmp/offshoots-verify/evidence` is kept. Build output (`dd/`) is also kept for the next run.
