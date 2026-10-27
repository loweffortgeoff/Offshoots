# Hindsight evaluation

2026-10-27 update: Hindsight review shows the selected event's note and current decision category, with a category filter. Nine focused summary/review tests and a generic iOS Simulator build passed. A subsequent focused rerun stalled in the simulator test runner and was stopped. An independent review found no actionable issue in the new review changes; it was not exhaustive across the branch. On iPhone 18 Pro (iOS 27.0), checks showed expected counts, combined filters, empty results, reset, dated navigation, and notes. Saved answers remained readable in locked preview; the long note wrapped at largest text in light mode, and dark-mode filter labels were readable after scrolling. Original Documents and preferences were restored and compared to the backup. Spoken VoiceOver, real-history paid value, and phone checks remain open.

Date: 2026-10-24. Status: local checks and independent-review fixes pass. Physical-device and paid-value acceptance remain open. Production purchase/capture remain disabled. Generated Reflection remains disabled separately.

## Scope and test inputs

The approved design records what someone would repeat or change at an existing outcome review or revisit. It uses explicit answers and the existing note, not a model interpretation. The first answer and each revisit remain separate dated records. Summary counts use the last answered recorded event per decision and its own outcome; a later skipped answer cannot change that pairing.

`docs/fixtures/hindsight-check-ins.json` contains nine authored synthetic decisions, eight with recorded answers. Expected counts are Same approach 2, Different approach 3, Different choice 1, Not sure 2. It includes a pending decision, a first answer without a note, a skipped later answer, tied/backdated revisits, long writing, Good + Different choice, and Bad + Same approach. It does not recreate the exact missing Ghost PTO model-regression records.

## Automated and local StoreKit evidence

The final regular xcresult summary reports **255 passed, ten opt-in tests skipped, zero failed** on iPhone 18 Pro (iOS 27.0). Parameterized leaf counts differ. Task-level regular suites also passed after data, access, capture, and review changes. New regressions were observed failing before the relevant changes: missing persistence/event pairing, verification uncertainty, delayed refresh after revocation, startup subscription order, a stale first-review overwrite, and combined filter toggles.

The opt-in `HindsightStoreKitIntegrationTests` and synthetic fixture test pass. The local test creates a transaction with `SKTestSession` for existing product `com.geoffrey.silva.Offshoots.reflection`, confirms capture while generated Reflection is unavailable, invokes Restore, then refunds and verifies no new structured answer is saved. Recorded answers remain reviewable/exportable. Simulated product-loading and App Store sync network errors leave verified ownership intact. A new Restore uncertainty assertion failed before the controller fix and passes after: verification uncertainty now says it could not verify the purchase, rather than claiming no earlier purchase exists.

This is local StoreKit evidence. It does not establish a purchase-button flow or sandbox behavior on a phone. The regular suite leaves opt-in tests skipped; report its result bundle counts separately from this explicit run.

## Simulator evidence

Running-app checks passed on iPhone 18 Pro, iOS 27.0, UDID `204520A6-E5B5-447D-8A6B-028317014DD8`, on the Mac mini with macOS 27.0.1 and Xcode 27.1 (27A9275). Observed the expected 2/3/1/2 counts, combined filters, empty intersections, dated current-detail navigation, first answer without a note, skipped-answer pairing, tied/backdated history, capture/clear/save, default-unanswered revisits, retained first history, and byte-identical cancellation. Locked entry, Settings Restore response, and saved reading with capture disabled also passed. No Buy button was tapped.

The first visual pass found a clipped largest-text outcome picker and the spoken label “1 decisions.” A wrapping native Menu and singular label fixed both. A second Xcode-driven pass confirms full “All outcomes” in both themes at the largest text size, working filters, exact AX label “Different choice, 1 decision,” full dark long-note history, and light Mark Outcome choices with one note field. Default and largest-text paywall coverage is representative in both themes. This is not a full screen-by-screen theme/size matrix or actual VoiceOver listening.

Local screenshots and detailed reports are retained at `/tmp/offshoots-hindsight-evidence-2026-10-24/ui/` and `ui-retest/`. These are local temporary artifacts, not tracked release images. Original Documents and preferences were backed up before seeding; the original Documents and preferences were restored to the current post-test app container and verified against backup hashes. The app is terminated and content size is Large.

The initial Xcode gesture command returned `Invalid command: 'swipe'. To recover, review again all available commands in device-interaction skill`. That pass continued with the T3 device driver. The retest used the installed Xcode verification runbook and correct gesture syntax; no fallback was needed. Xcode reported `applicationState: NotRun` despite a live hierarchy and working interactions. App verification uses the observed hierarchy and screenshots, not that status label.

## Release and ownership boundary

The Release simulator build passes. Its executable contains none of the three Hindsight Debug launch-flag strings. The production Hindsight factory creates no purchase or entitlement service while disabled. Generated Reflection's release gate remains false. Debug preview ownership is isolated behind Debug compilation; preview Buy cannot run a transaction. Existing saved hindsight remains readable even when capture is disabled or ownership is absent.

Previously verified ownership is retained through verification uncertainty within the process. Cold-launch/offline access relies on StoreKit's locally verified transaction cache; no preference is independent proof of purchase. A verified accepted-product revocation or a clean empty entitlement snapshot removes capture access. Physical offline relaunch must be checked separately.

## Independent review and fixes

A fresh GPT-6 Astra review checked the whole branch through `1b70f5f`, including all five Hindsight review-focus areas. It found one Important issue: Restore used a historical ownership-resolution flag, so a clean startup check followed by verification failure could still claim no earlier purchase existed. The new parameterized local StoreKit regression reproduced that failure for both a prior owner and a prior nonowner. The controller now uses the latest verification result separately from retained access. Both cases and recovery to a later clean check pass. No second review was claimed; the corrective pass is verified by tests and a green regular suite/Release build.

The reviewer also found missing `ReflectionHistoryStore` injection in the updated Analytics and Settings previews. Both preview environments are repaired and compile with the app. Canvas rendering was not separately measured. This related preview repair was folded into the same pass under Geoff's standing project instruction.

Review boundaries retained: generated Reflection quality/activation remain deferred; phone/VoiceOver/offline/sandbox evidence remains open; real-history value and paywall sentences require Geoff's acceptance. He set the name to Hindsight and the United States price to $5.99 on 2026-10-24. Signing, distribution, and submission readiness are not established by this local review. These boundaries prevent an unsupported release claim, not completion of the approved local implementation.

## Open acceptance gates

- Physical-device usability, VoiceOver listening, offline relaunch ownership, and phone sandbox purchase-button/Restore/refund checks.
- Geoff's review of real histories for useful distinctions beyond the existing free notes and timeline. Correct counts are not proof of paid value.
- Paywall sentences, and a check that the App Store localization display name and description match the local StoreKit files. Those files now say Hindsight and "Record what you would repeat or change." The reference name and United States price ($5.99, proceeds $5.09) are recorded; status remains Prepare for Submission. No upload, review submission, merge, push, or release is part of this implementation.

## Reproduction

Use only the allowed iPhone 18 Pro destination. Run ordinary tests with live model/StoreKit gates off. Run the local StoreKit suite explicitly:

```sh
TEST_RUNNER_HINDSIGHT_STOREKIT=1 xcodebuild \
  -project Offshoots.xcodeproj -scheme Offshoots \
  -destination 'platform=iOS Simulator,id=204520A6-E5B5-447D-8A6B-028317014DD8' \
  -parallel-testing-enabled NO \
  -only-testing:OffshootsTests/HindsightStoreKitIntegrationTests \
  -only-testing:OffshootsTests/HindsightFixtureTests test
```

For UI checks, terminate the app before replacing its decision JSON. Back up original records and preferences first. Use `-HindsightPreview` for owned layout, `-HindsightLocked` for locked layout, and `-HindsightStoreKit` only with the local StoreKit test configuration. Preview flags cannot enable production capture. Restore the original simulator files and content size when done.
