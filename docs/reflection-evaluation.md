# Reflection evaluation

Status: Local engineering checks pass. Both local-model and PCC generated-text quality gates fail. Physical-device acceptance is not claimed.

## Cases and scoring

`fixtures/reflection-acceptance.json` has 36 authored synthetic cases. The source fixture contains planted themes; passing it is not proof of real-world usefulness. Lifecycle cases include explicit actions after generation.

Record case ID, source scope, prompt/model version, device, OS, locale, model availability, elapsed time, raw response, displayed response, and completion/error/cancellation. Raw and displayed content must come from the same response. Evaluate saved-history lifecycle cases separately from text quality.

Hard fail: invented facts, reversed facts/meaning/ratings, prompt leaks, or invalid support references. Eligible useful output must add a specific supported observation. At least 90% of eligible outputs must pass; empty/filtered/error results remain in the denominator. Score correct abstention separately. For supported physical-device requests, target 95% within 10 seconds; failures/timeouts remain in the denominator. Unsupported/skipped cases are unmeasured, never passes.

## Missing real evidence

Exact source records for Groceries, Ghost PTO, More Ghost PTO, the recorded input-copying case, and the 2026-10-01 command-like cleanup case were not found in the repository search on 2026-10-24. Keep these cases pending. Do not reconstruct them from issue summaries. Their absence blocks final quality acceptance, not local implementation.

## Baseline

On 2026-10-24 this Mac (macOS Darwin 27.0, Xcode 27.1 build 27A9275) passed 202 unit tests on iPhone 18 Pro (iOS 27.0). The opt-in live model suite was excluded by its existing environment gate. Physical-device output, usefulness, and latency remain unmeasured.

## Local implementation evidence — 2026-10-24

Geoffrey's Mac mini runs macOS 27.0.1 (26A434) and Xcode 27.1 (27A9275). The final automated run passes 238 tests in 33 suites on iPhone 18 Pro (iOS 27.0), including one local StoreKit integration test. The opt-in model diagnostic is excluded from that count. The final Release simulator build also passes.

The model is available on this simulator. The first 36-case diagnostic run exposed copied individual notes: 18 of 26 labeled eligible cases returned no generated observations; seven cases returned preflight errors/abstentions. The live purchase-sample assertion failed. That baseline did not meet the paid-quality gate.

A simpler one-connection schema and short request-local references then produced the captured purchase example in `fixtures/reflection-purchase-sample.json`. The next 36-case diagnostic run completed, but also exposed command-like text being repeated. Recognizable model-control text is now omitted whole before generation; original journal records stay intact. This conservative exclusion is not proof against every instruction-like input.

Decision readings now use only their own recorded stages. Code supplies the rating timeline; the model may add one comparison between two cited stages. Saved-history access, refund/source-change request invalidation, failed writes, and coordinated backup rollback have unit evidence. Fake-output UI checks cover generation, refresh, relaunch history, evidence navigation, light/dark, and largest text. Independent review found two implementation blockers: rating-only revisits counted as written evidence, and provider occupancy did not survive navigation/retries. Both are fixed with regressions. The final artifact UI check passed saved history/evidence navigation, Settings counters/data controls, paywall light/dark/largest text, and Release ignoring Debug flags.

Physical-device quality, cleanup meaning preservation, usefulness scores, sandbox purchase/Restore/refund, and the exact real-note regressions remain unaccepted. Production paid Reflection remains disabled. Local model results do not clear those gates.

## Final scored diagnostic — commit 2a86e7f

The [case-by-case record](evaluations/2026-10-24-reflection.json) contains raw and displayed output from the same response, selected source mappings, elapsed time, and author scoring for all 36 frozen synthetic cases. The harness completed successfully; that is capture success, not quality acceptance.

- Useful, supported core readings: **6 of 17** eligible cases. The frozen eligibility labels were retained, including cases where conservative exclusions or omitted optional output produced no added insight.
- Correct sparse/unrelated-data abstention: **8 of 10** cases. Two unrelated inputs still receive forced connections.
- Meaning preserved in the five synthetic cleanup cases: **5 of 5**. Exact real-note cases and physical-device fidelity remain open.
- Four lifecycle cases are excluded from text-usefulness scoring. Their state changes have separate automated history/request/backup/StoreKit checks; the diagnostic itself generates text only.

These are author judgments on a small synthetic set, not a statistical estimate or the physical release score. The zero-unsupported-facts gate already fails: Work output invents a meeting/availability check for one record; a long-history output treats a fast annoyed reply as checking information; other comparisons add unrecorded mental states or chronology. Spanish and French inputs receive English observations. The ratings calculated by code remain correct.

The next quality task is to remove these unsupported claims, force meaningful abstention, and honor the notes' language against this frozen set before attempting release acceptance. Reference validation proves that cited records exist. It does not prove that the generated sentence follows from them. Production activation remains blocked.

## Verification boundaries

The local StoreKit check creates a transaction with `SKTestSession`, checks app entitlement, invokes Restore, and checks refund revocation. It does not prove a successful purchase-button flow or sandbox behavior on a phone. The earlier direct purchase-button harness call did not return; the automated check uses the documented test-session purchase API. Refund delivery is asynchronous and is checked with bounded condition polling.

Final UI checks used Xcode interactions and screenshots on the allowed simulator. Full backup/restore rows and destructive confirmation copy were inspected; round-trip and interrupted-write behavior have automated evidence, not a complete Files-picker UI round-trip. No purchase was attempted in the paywall preview. VoiceOver listening and physical-device testing remain open.

An Apple Account sign-in prompt appeared during the Release smoke check and was cancelled. Its cause was not established; local StoreKit tests had run earlier. Release paid entry points remained absent, and the disabled factory is covered by tests. The earlier transient evidence-link exit did not recur in the final serial check. Simulator files/preferences were restored and the app was terminated.

## PCC comparison — 2026-10-24

Geoff approved the evaluation. `dev/paid-reflection` was fast-forwarded to entitlement commit `fe73b78`. The project now configures `com.apple.developer.private-cloud-compute` for both app configurations. PCC reported available and below quota on iPhone 18 Pro (iOS 27.0, build 24A434), on Geoffrey's Mac mini with macOS 27.0.1 and Xcode 27.1. An actual request returned `Ready`. Account entitlement enablement was reported by Geoff; membership/download eligibility was not independently checked in the developer portal; runtime access is confirmed for this simulator only.

The [scored PCC record](evaluations/2026-10-24-pcc-moderate.json) preserves all 36 captures, source snapshots, actual prompts/instructions, response caps, raw structured output, displayed output from the same response, timing, availability/quota, errors, author scores, and source hashes. The provider exists only in the test target; its shared-service seam compiles only in Debug. No production backend was selected. Paid Reflection remains disabled.

Inputs, prompts, schemas, validation, the 1,800-byte snapshot budget, and the local token-count preflight match the frozen baseline. PCC uses moderate reasoning, greedy sampling, and the same 400-token reading/500-token cleanup response caps. The diagnostic also checks cleanup for comparison; this does not approve PCC for cleanup. Expanded context and different prompts were not tested.

- Useful, supported core readings: **7/17**, versus **6/17** locally. Sparse/excluded/filtered eligible cases remain in the frozen denominator. Scores are author judgments; borderline wording and usefulness calls are explained per case.
- Correct abstention: **8/10**, unchanged. All eight successes came from shared app preflight, not model abstention. Both unrelated inputs still received forced connections.
- Synthetic cleanup meaning: **5/5**, unchanged. Exact real-note fidelity remains open. Spanish and French readings still returned English.
- Captured 27 model responses and nine shared preflight rejections. No attempted model request failed or exhausted quota. Two rating/metadata-only generated comparisons were filtered out. Four lifecycle cases remain generation-only, outside text-quality scoring.
- Simulator response-path latency: median **1.29 s**, nearest-rank p95 **1.84 s**, maximum **3.23 s**; 27/27 attempted requests completed within 10 seconds. Preflight rejections are reported separately. These results do not establish physical-device latency.

The quality gate still fails. A long-history sentence calls paint sample pots “written material.” Other outputs infer unchecked details or unsupported chronology, and the unrelated cases force generic themes. Cleaner Work output and some supported timeline comparisons do not clear the zero-unsupported-facts or 90% useful-output gates. A larger model alone did not solve the problem under these prompts.

### Engineering verification and reproduction

The transport regression failed before the seam was connected and passed after implementation. It checks that an evaluation-provider failure reaches the caller without local fallback. The regular xcresult summary reports 233 passed, eight opt-in tests skipped, zero failures; parameterized leaf counts differ. Model diagnostics and local StoreKit integration were disabled for that regular run. The separate PCC suite passes two capture/access tests; this is capture success, not text-quality acceptance. The Release simulator build passes and contains no PCC provider or responder-seam symbols. Xcode emitted its existing App Intents metadata and OS-build parsing warnings.

Run the full opt-in suite with a fresh absolute capture path. Method-only filtering without parentheses selected zero tests during setup; that empty run was discarded. Require two executed tests and 36 capture rows:

```sh
TEST_RUNNER_REFLECTION_PCC=1 \
TEST_RUNNER_REFLECTION_PCC_OUT=/tmp/offshoots-pcc-new-run.jsonl \
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots \
  -destination 'platform=iOS Simulator,id=204520A6-E5B5-447D-8A6B-028317014DD8' \
  -parallel-testing-enabled NO \
  -only-testing:OffshootsTests/ReflectionPCCOutputTests test
```

The harness refuses to overwrite an existing capture. Each record is written after the case completes; a process kill during a request can leave that case uncaptured. Keep the result bundle/log and check all 36 IDs before scoring. This comparison retains the on-device token preflight, so it does not establish PCC operation when the on-device model is unavailable.

## Next quality work

Keep production paid Reflection disabled. Review the frozen failures before another prompt/schema experiment. Keep context expansion separate so it does not obscure this comparison. Do not choose a production backend from this result. Physical-device quality/latency, exact missing real-note cases, VoiceOver, and phone purchase/Restore/refund remain open.

PCC requires iOS 27+, eligible Apple Intelligence hardware/region, internet, and daily user quota handling. Explain these limits before purchase; a one-time app unlock must not imply unlimited generations. Keep saved readings available offline or at quota exhaustion. Use local generated readings as a fallback only after they pass the same quality gate. See [Apple's access requirements](https://developer.apple.com/private-cloud-compute/) and [integration guidance](https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute).

## Context and PCC full-context results (2026-10-28)

More context let Patterns read 17 of 17 decisions instead of 6. On the 23 graded Patterns cases (citation-only grade): on-device free choice 21/23, on-device code-chosen pairs 19/23, PCC free choice 22/23, PCC pairs 20/23. PCC abstained on `unrelated`; both still force a connection on `same-outcome-different-notes`. Neither clears the quality gate. The prototype code is not on this branch (`dev/reflection-context-prototype`). Findings: [2026-10-28 findings](superpowers/archive/2026-10-28-reflection-context-findings.md). Frozen result: [2026-10-28-pcc-full-context.json](evaluations/2026-10-28-pcc-full-context.json).
