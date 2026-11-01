---
name: verify-offshoots
description: Build and drive the Offshoots iOS app (SwiftUI decision journal, bundle com.geoffrey.silva.Offshoots) on a throwaway iOS Simulator to prove a change works as a user would see it. Use after UI or store changes, or when asked to "test on the simulator" or "verify" Offshoots.
---

# Verify Offshoots

Surface: iPhone app, five tabs (Dashboard, Log, Decisions, Insights, Settings). Data is one file, `Documents/decisions.json`, so every proof checks the screen and that file. Project facts (fixtures, launch args, simulator quirks) live in `CLAUDE.md`; read its "Simulator Testing" section if something odd happens.

`AGENTS.md` authorizes isolated simulator use without per-session approval. Any compatible iPhone, iPad, or Duo model is allowed; create a separate instance for Pro Max captures.

Everything below uses `.claude/skills/verify-offshoots/verify.sh` (call it `V`). Export a unique `RUN_ID` once per task and reuse it for every command; state is isolated under `/tmp/offshoots-verify/$RUN_ID`.

## Launch
1. `export RUN_ID="offshoots-$(date +%Y%m%d-%H%M%S)"`, then `V up` builds Debug with Xcode 27.x (`/Applications/Xcode.app`), creates a **new** `verify-offshoots-$RUN_ID` simulator using `SIM_DEVICE_TYPE` (defaults to iPhone 18 Pro) and the newest installed iOS runtime (or `SIM_RUNTIME`). It prints `READY sim=...`. First build is about 3 min. It starts from an empty data folder; the app launches with no decisions.
2. `V seed screenshots` loads 12 decisions (4 "Ready to Review") and relaunches with the splash skipped. Other fixtures: `ls docs/fixtures`. `insights-seed` fills Insights only when today is 2026-09-25..30; `so-far-trend` and `screenshots` do not depend on the date.
3. Open the simulator for driving: call `V sim` to get this run's UDID, then T3 `device_list` and `device_open` (deviceId is that UDID, hostId `local`). It returns an `agent-device` command; use it for every tap, fill, scroll and screenshot. Without T3 tools, use the Xcode `DeviceInteractionStartSession` tools (see `device-verification-xcode27`). Then `agent-device open com.geoffrey.silva.Offshoots` (add `--relaunch` only if you want a fresh start; it keeps the seeded data).

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
Save to `/tmp/offshoots-verify/$RUN_ID/evidence/<feature>-<step>.png` with `agent-device screenshot <path>` (1x points; add `--pixel-density 3` for full res). Per proof capture: the screen before the action, the screen after, and `V db "<title>"` output. Standards:
- Use the real UI path. Do not edit `decisions.json` to create the state you are testing; seeding fixtures before the run is fine.
- The store writes `decisions.json` a few seconds after the UI changes, so `V db <title>` polls up to 20 s. A missing row after that is a failure.
- A UI change with no matching file change (or the reverse) is a bug, not noise.
- A saved decision schedules a local notification; that is the only external side effect, and it stays on the simulator.

## Isolation
`V up` creates and uses a dedicated simulator for this `RUN_ID`. Never boot, reuse, erase, or interact with Geoff's active simulator instance, whether it is an iPhone, Pro Max, Duo, or another model. Unclear ownership means create another simulator. Distinct run IDs have separate state and can coexist. Tests (`xcodebuild test`) shut their target simulator down, so run tests against this task's owned UDID and do not interrupt an active proof.

## Cleanup
Close this run's T3 device with `device_close` (shutdown true). Then `V down` deletes only this run's simulator; its evidence in `/tmp/offshoots-verify/$RUN_ID/evidence` and build output stay.
