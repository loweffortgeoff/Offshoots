# CLAUDE.md — Offshoots

Project notes for Offshoots. General guidelines live in `../CLAUDE.md`.

# Development Commands

## Build Verification

One shared scheme, `Offshoots`. Targets: `Offshoots` (the app) and
`OffshootsTests` (Swift Testing, hosted by the app). Unit tests cover logic.
Check UI behavior on the simulator.

```
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'generic/platform=iOS Simulator' build
```

Leave the output verbose. Do not add `-quiet`.

## Tests

```
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' test
```

The tests load `docs/fixtures/*.json` from the test bundle. The folder is a
synced group in `OffshootsTests` only, so tests also run on a device, and a
new fixture file is picked up with no project change. `AnalyticsEngineTests`
pins "now" to 2026-09-27. If you change a fixture, update the expected values in the
tests too.

**Live output harness.** `ReflectionLiveOutputTests` runs the real on-device model
on `docs/fixtures/reflection-notes.json` (Patterns, two decision reflections, Look
Back for Money and Work) and writes token counts, prompts and output to a file. It
is off by default. Delete the output file first: the harness adds to the end of it.

```
rm -f /tmp/reflection-live.txt; TEST_RUNNER_REFLECTION_LIVE=1 TEST_RUNNER_REFLECTION_LIVE_OUT=/tmp/reflection-live.txt xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -only-testing:OffshootsTests/ReflectionLiveOutputTests test
```

Tests run in a cloned simulator, so `print` output from a test does not reach
the xcodebuild log (checked 2026-10-05). That is why the harness writes to the
`REFLECTION_LIVE_OUT` file on the Mac. Prompt changes, measurements and output
per version are in `docs/superpowers/archive/2026-10-05-reflection-depth.md`.

**Context window.** The on-device model's context is 4,096 tokens on iOS 26
(a fixed value in the SDK) and 8,192 on the iOS 27.0 simulator. Size every
Reflection prompt for 4,096. `theWorstCasePatternsPromptStaysSmall` pins Patterns.

Bundle ID: `com.geoffrey.silva.Offshoots`.

## Simulator Testing

- **Do not wait on real time. Seed data instead.** The store reads
  `Documents/decisions.json` from the app's data folder. The file is an array of
  `Decision` with ISO 8601 dates. Write backdated decisions there, then relaunch
  the app:
  ```
  C=$(xcrun simctl get_app_container <UDID> com.geoffrey.silva.Offshoots data)
  cp seed.json "$C/Documents/decisions.json"
  ```
  Terminate the app before you write the file, because the store saves on
  every change. Keys that are missing (`stakes`, `revisits`, `resolvedAt`)
  decode to their defaults.
- **Seed script:** `scripts/seed.sh <fixture>` closes the app, copies
  `docs/fixtures/<fixture>.json` in as `decisions.json` and relaunches.
  Run it with no argument to list fixtures. `SIM=<UDID>` picks another
  simulator. The app must be installed there first. The default UDID is the
  Mac mini's iPhone 18 Pro. On the MacBook Pro, set
  `SIM=22F3F961-2FD9-47A0-9158-24A94F6871B4`.
- **One "iPhone 18 Pro" simulator per Mac.** A second simulator with the same
  name makes `-destination '…,name=iPhone 18 Pro,OS=27.0'` fail with "Unable to
  find a device matching". On 2026-10-05 the MacBook Pro had an unused duplicate
  (`5BD73D53…`); Geoff approved deleting it. If the error comes back, run
  `xcrun simctl list devices available | grep "iPhone 18 Pro"`, or use `id=`.
- **App Store screenshots:** `scripts/screenshots.sh` erases the iPhone 18 Pro
  Max (iOS 27.0), sets dark mode and a 9:41 status bar, builds, installs and
  loads `docs/fixtures/screenshots.json`. The fixture is anchored to 2026-09-27,
  and the script moves every date by the number of days between the anchor
  and today, so the shots never drift. `scripts/seed.sh screenshots` loads
  the same fixture without the date shift, so its dates drift after
  2026-09-27. `ScreenshotFixtureTests` pins the numbers. Capture with
  `scripts/screenshots.sh shot 01-dashboard`; files go to
  `~/Documents/Dev Workstation/App Images/ASC Screenshots/Offshoots/Captures/<date>/`.
  The shot list and scroll positions are at the top of the script. Do not save
  on 02 (Log) or 04 (Revisit): a save asks for notification permission.
  The 6.9" capture size is 1320 × 2868 px.
- **iPhone Duo screenshots (2026-10-08):** run
  `DEVICE="iPhone Duo" scripts/screenshots.sh`. The script picks Xcode 27.1 RC
  and iOS 27.1, and writes to `Captures/<date>/duo/`. The Duo has two displays.
  `shot <name> closed` captures `primary` (1398 × 2034). `shot <name> open`
  captures `primary-1` (2007 × 2853, or 2853 × 2007 in landscape). Both are ASC
  sizes. The script warns when the size is wrong. Only Geoff can fold the Duo
  (DeviceHub). `scripts/screenshots.sh reload` puts the date-shifted fixture
  back and relaunches, with no erase. Use it after a stray save.
  - **Which posture:** use closed for the single-screen shots (01, 03–07).
    Use fully open landscape for Log (02) and for two-pane Decisions (08).
    Partly open puts a single-pane screen in one half and leaves the other
    half empty, which does not work as a promo image.
  - **Wait for the model.** On a fresh install the Clean Up Note and
    Reflection areas read "on-device model is still getting ready" and do not
    clear on their own. Terminate and relaunch the app. The log then says
    `Current availability state: available`, and the areas show a lock.
  - **Typing drops characters on the Duo.** The simulator `text` action lost
    letters ("Mo the Denver officev"). Type short chunks and check each
    one, or paste. The Mac pasteboard overrides `simctl pbcopy`, so put the
    text on the Mac with `pbcopy` first. Then long-press the field, tap
    the caret, tap Select All, and tap Paste.
  - **Wait after a tap.** The page can still be settling after a tab change
    or fold, and a tap then misses the field. Take a screenshot first.
  - **Do not save on 02 or 04.** A stray save adds a 13th decision. Run
    `reload` to put the data back to 12.
- **Insights fixtures:** `docs/fixtures/insights-seed.json` gives Good 50%,
  Top Category Tied, Trend Improving, Accuracy 67% (4 correct, 1 close,
  1 missed) and Optimistic (0.5 steps, 6 decisions) when today is 2026-09-25 to 2026-09-30. The trend windows move
  with today's date, so update the dates later. `insights-seed-too-early.json`
  gives Trend "Too early".
  `so-far-trend.json` gives Trend "So far" Improving (6 marked in July 2026,
  both 30-day windows empty), and it does not depend on today's date.
- **Test pushes need permission first.** `xcrun simctl push` fails with "Source
  is not authorized" until someone taps Allow in the app. The app asks the
  first time it schedules a reminder. `simctl privacy grant notifications`
  does not work. The push payload needs a `decisionID` key with the
  decision's UUID.
- **Toggle preset:** the Settings "Follow-up Reminders" toggle is the
  UserDefaults key `notificationsEnabled`. `simctl spawn … defaults write`
  before launch reaches the app. `defaults read` afterwards can return an
  out-of-date value. Read the app's own plist instead:
  `$C/Library/Preferences/com.geoffrey.silva.Offshoots.plist`.
- **Tapping in the simulator:** Claude's own simulator tool (`tap`, `swipe`)
  works on the Mac mini (checked 2026-09-25). Take screenshots with
  `xcrun simctl io <UDID> screenshot`. Coordinates are device points: the
  iPhone 18 Pro screen is 402 × 874 pt, and the iPhone 18 Pro Max screen is
  440 × 956 pt. `sips -Z 956` scales a Pro Max capture to 1 px = 1 pt, so you
  can read tap coordinates from it (`-Z 874` for the Pro). Xcode's
  device-interaction tools (`XcodeOpenWorkspace`, then
  `DeviceInteractionStartSession`) are the backup.
- **Scrolling to an exact position:** use `touch_path` with slow steps and a
  pause before the lift. A flick keeps moving after release. The first small
  drag after the scroll stops is sometimes ignored; send it again (checked
  2026-09-26). A large navigation title (Decisions, Insights) only stays fully
  open or fully collapsed, so you cannot hold a small scroll offset there.
- **Uninstalling resets both permission and data, but not a `defaults write`.**
  A value written with `simctl spawn … defaults write` lives outside the app
  container and survives an uninstall. On 2026-09-25 a leftover
  `notificationsEnabled = 0` on the iPhone 18 Pro simulator turned reminders
  off after a fresh install. Check with `simctl spawn <UDID> defaults read
  com.geoffrey.silva.Offshoots`, and clear it with `defaults delete`.
- **If every notification `add` fails, erase the simulator.** On 2026-09-25
  the iPhone 18 Pro simulator logged `Added notification request: [ hasError: 1 ]`
  on every add and showed no permission prompt. `simctl shutdown`, then
  `simctl erase`, fixed it. The erase also resets the simulator to light mode.
  Check with `simctl spawn <UDID> log show --last 1m --info --predicate
  'process == "Offshoots" AND subsystem BEGINSWITH "com.apple.UserNotifications"'`.
- **A test run shuts the simulator down.** After `xcodebuild … test`, the
  iPhone 18 Pro is Shutdown (checked 2026-09-25, with `name=` and `id=`).
  Boot it again with `xcrun simctl boot <UDID>` before `simctl ui`,
  `install` or `seed.sh`.
- **Reattach after a reinstall.** After `simctl install` or a reboot, the
  simulator tool's taps can stop reaching the app. Call `attach` again.
- **Do not start a swipe near the tab bar.** A swipe that starts at y ≥ 800
  on the iPhone 18 Pro taps the tab under it. Start at y = 720 or higher up.
- **Accessibility tree without VoiceOver:** `DeviceInteractionStartSession`
  with the simulator UDID, then `DeviceInteractionSynthesize` (optionally
  with `interactionCommand: "t x y"`) writes a hierarchy file with each
  element's label and traits (`Selected`). End the session afterwards.
  Coordinates in that file are device points.
- **Dynamic Type checks:** `xcrun simctl ui <UDID> content_size
  accessibility-extra-extra-extra-large`, then `large` to reset. At
  accessibility sizes, layouts switch with `dynamicTypeSize.isAccessibilitySize`
  (AnyLayout: side by side, or stacked). Chart text is capped at `.xxxLarge`.
- **Splash on the first cold launch of each day.** The splash shows for
  2 seconds; taps in that time miss. Later cold launches that day, and
  returns from the background, skip it. The day is `lastSplashDate` in the
  app's plist (`SplashSchedule`). To see it again, launch with
  `-lastSplashDate 0` (`simctl launch <UDID> <bundle> -lastSplashDate 0`,
  or enable that argument in the scheme; do not commit it enabled). A
  `simctl spawn … defaults write` after the app has run did not take
  effect (checked 2026-10-09); the launch argument does. The launch screen
  is the app background (`OffshootBackground`, `UILaunchScreen` in
  `Offshoots/Info.plist`), so a launch with no splash shows no green. After
  a launch-screen change, uninstall the app, then shut the simulator down
  and boot it again: iOS caches the launch screen.
- **Menus close on their own.** Take a screenshot after opening a Picker
  menu and tap the item at once. A late tap can land on the row behind it;
  on 2026-09-25 one opened an App Store link in Safari from Settings.
- **Simulator tool taps:** pass `duration: 0.15`. Shorter taps sometimes miss
  a Toggle. The tool's own screenshot can lag; `xcrun simctl io` is current.
  The `text` action can drop characters: on 2026-09-26 "Test" arrived as
  "Te". Check the field in a screenshot before you rely on the text.
- **Calendar day taps need a free path.** Do not put an always-on tap
  gesture on a container that holds a graphical `DatePicker`. It takes the
  day taps, and only the month arrows still work (fixed 2026-09-26). The
  forms turn their tap-to-close-the-keyboard gesture on only while a text
  field has focus: `.gesture(_:including: focused ? .all : .subviews)`.
- **The first tap after a launch is often lost.** After `simctl launch`
  the first tap (often a tab-bar tap) did nothing several times on
  2026-10-01. Take a screenshot, and send the tap again if the screen did
  not change.
- **Reflection launch arguments (DEBUG builds only).** `-ReflectionFake` gives
  canned output, unlocked. `-ReflectionUnlockOnly` uses the real on-device
  model, unlocked, with no purchase. Type the leading dash, also in Xcode's
  scheme Arguments field: without it the argument does nothing. With no
  argument the surfaces show the locked state. There is no `-ReflectionPaywall`
  argument. In the shared scheme `-ReflectionUnlockOnly` is present but
  disabled (`isEnabled = "NO"`). Do not enable it in a commit: every Xcode run
  would start unlocked and the paywall could not be tested. Commit
  `b792f1c` on `main` enabled it; the `reflection` merge is a fast-forward, so
  confirm it is disabled on `main` afterwards.
- **Purchases need an Xcode run.** `Reflection.storekit` is on the scheme's
  Run action. `simctl launch` ignores it. Run with ⌘R or the Xcode
  `RunProject` tool. The test purchase sheet says you are not charged.
- **On a phone, buy in the sandbox, not in Xcode test mode.** Xcode's test mode
  fails on both phones with `ASDServerErrorDomain Code=2010`. Take
  `Reflection.storekit` off the Run action by hand (do not commit that), sign in
  under Settings > Developer > Sandbox Apple Account, and run from Xcode. See
  DECISIONS 2026-10-01. The Xcode sheet reads "For testing purposes only. You will
  not be charged for confirming this purchase." The TestFlight sheet (build 2, iPhone 17, 2026-10-02) has the same
  testing line, headed "In-App Purchase", with no "[Environment: Sandbox]" text.
- **Uninstalling clears the Xcode test purchase.** Buy again in the running
  app. Manage Transactions is empty until then.
- **Import test files on the simulator.** Copy a JSON file into each
  `…/Containers/Shared/AppGroup/<id>/File Provider Storage/` folder of the
  simulator. It shows in Files > On My iPhone.
- **Long text input:** `simctl pbcopy` puts text on the simulator
  pasteboard. Long-press the field and tap Paste.
- **Xcode rewrites the shared scheme.** When Xcode opens the project, it
  changes the `version` in `Offshoots.xcscheme` from 1.7 to 1.3. Do not
  treat that diff as Geoff's edit.
- **The simulator runs the real on-device model.** On the Mac mini
  (checked 2026-10-01) and the MacBook Pro (checked 2026-10-05), the iOS 27.0
  simulator reports `SystemLanguageModel` as available and gives real output.
  A call takes 3 to 7 seconds. Greedy sampling gives the same output
  for the same input, so a prompt change can be re-tested on the simulator.
- **App theme on the simulator.** The Settings theme is the `appTheme` key
  in the app's own plist. On 2026-10-01 a `plutil` edit of that key, made
  with the app closed, did not take effect. The iPhone 18 Pro was on Dark.

## Test Device

The iPhone 17 Pro runs iOS 27.2 Beta 2. It builds from Xcode 27.0 on the Mac
mini (confirmed 2026-09-24). This is a test device, mostly used to confirm projects compile and build on a live device. It is connected to Xcode as `Geoff's iPhone` 

The iPhone 17 runs iOS 27 (non Beta, stable releases). It builds from Xcode 27.0 on the Mac mini (confirmed 2026-09-26). This is the device that is referred to when "testing" or "dogfooding" an app for N number of days or weeks (whichever the situation calls for). It is connected to Xcode as `Geoffrey's iPhone` and should be considered the device of record for any out of session or longer term (>1 day) testing.

Both devices also build from Xcode 27 on the MacBook Pro. 

# iPhone Duo (fold layout)

Spec: `docs/superpowers/specs/2026-10-07-duo-fold-layout-design.md`. Code: `Offshoots/Fold/`.

- **Offshoots builds only with Xcode 27.1 or later, on the Mac mini.** The fold
  APIs are in the iOS 27.1 SDK. Prefix commands with
  `DEVELOPER_DIR="/Applications/Xcode 27.1 RC.app/Contents/Developer"`. The app
  still runs on iOS 18.6: every 27.1 call sits behind `#available(iOS 27.1, *)`.
- **Posture table** (iPhone Duo simulator, from the probe): the `.division`
  region is active only when the device is partly open. Fully open it is still
  reported, as inactive; any other device reports none. The app uses that to
  tell the Duo from other iPhones (`FoldPosture`: `flat`, `unfolded`, `folded`). Closed 466 x 678, no
  region. Partly open portrait 669 x 951, band at y 455, 40 pt tall, 20 pt
  margins. Partly open landscape 951 x 669, band at x 455. Fully open: same
  sizes, region inactive.
- **Debug log lines** (DEBUG builds): `FOLDPOSTURE` and `FOLDPANE` show the
  posture and the pane fit. Read them with `simctl spawn <UDID> log show --last
  30s --info --predicate 'eventMessage CONTAINS "FOLDPANE"'`. Use them, not
  pixel positions, to check pane edges.
- **Only Geoff can fold and rotate the Duo**, in DeviceHub. The DeviceHub image
  of a bent device is scaled differently on each axis, so do not measure points
  from it. `simctl io screenshot` captures the display that is off in some
  postures (black image); the simulator tool's `screenshot` follows the active
  screen.
- **Gotchas found on the Duo.** A `NavigationStack` is a full-screen UIKit
  layer: a smaller `.frame` does not move its navigation bar, and the tab rail's
  trailing inset (84 pt) still reaches its content. `FoldPane` handles both: it
  gives a left pane extra width and cuts at the fold with a mask that reaches
  the screen edge. Extra height on a top pane hides the last scrolling content.
- **Checked on the Duo** (2026-10-07): a reminder tap in two-pane landscape opens
  the tapped decision in the detail pane (send it with `simctl push`; the app
  needs notification permission first). **Not checked:** the splash (launch with
  `-lastSplashDate 0`).

# Archive and upload

`scripts/archive-upload.sh` archives Release with Xcode 27.1 RC and uploads the
build to App Store Connect (TestFlight). It refuses a dirty tree and an enabled
`-ReflectionUnlockOnly`. `--archive-only` stops before the upload. Bump
`CURRENT_PROJECT_VERSION` first. It was run by hand for 2.0.0 (6) on 2026-10-09.
The upload is outward-facing: run it only when Geoff asks.

# Colors

Adaptive colors live in `Assets.xcassets` with light and dark values.
Xcode generates a `Color` symbol for each one (`OutcomeGood` becomes
`.outcomeGood`), so do not declare the same name in `Color+Theme.swift`:
the build fails with "invalid redeclaration". `Color+Theme.swift` keeps the
fixed raw palette (`offshoots…`) for the splash, plus `offshootPrimary` and
`outcomePending`.

On iOS 27.0 the graphical `DatePicker` draws the selected day in the label
color and ignores the tint. iOS 26.5 uses the tint (checked 2026-09-25).

Swift Charts axis labels keep the color they had at launch when light and
dark mode switch while the app runs. `CategoryBreakdownCard` uses
`.id(colorScheme)` to rebuild. To test a color change, switch the appearance
while the app is running, not only before launch.

# Docs

- The audit and plan docs live in `docs/`. The 2026-09-23 audit doc lists the
  remaining sections (5–6).
- `.gitignore` does not ignore Markdown, so a new doc is tracked with no
  exception. It ignores Xcode user state, build output, AI tooling folders,
  PDFs and OS files.
- Keep CHANGELOG, DECISIONS and TODO up to date as described in `../CLAUDE.md`.
- Release docs: `RELEASE_NOTES.md` (NEW / IMPROVED / FIXED / What to Test per
  version) and `ASC_LISTING.md`. The CHANGELOG keeps `## In Progress` on top;
  the release pass moves those entries under `## Shipped` → `### <version>`.
  Releases are tagged `v<version>`; the first tag is `v2.0.0`.
