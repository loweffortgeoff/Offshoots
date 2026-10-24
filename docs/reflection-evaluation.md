# Reflection evaluation

Status: Evaluation inputs prepared. No model-quality or physical-device acceptance is claimed.

## Cases and scoring

`fixtures/reflection-acceptance.json` has 36 authored synthetic cases. The source fixture contains planted themes; passing it is not proof of real-world usefulness. Lifecycle cases include explicit actions after generation.

Record case ID, source scope, prompt/model version, device, OS, locale, model availability, elapsed time, raw response, displayed response, and completion/error/cancellation. Raw and displayed content must come from the same response. Evaluate saved-history lifecycle cases separately from text quality.

Hard fail: invented facts, reversed facts/meaning/ratings, prompt leaks, or invalid support references. Eligible useful output must add a specific supported observation. At least 90% of eligible outputs must pass; empty/filtered/error results remain in the denominator. Score correct abstention separately. For supported physical-device requests, target 95% within 10 seconds; failures/timeouts remain in the denominator. Unsupported/skipped cases are unmeasured, never passes.

## Missing real evidence

Exact source records for Groceries, Ghost PTO, More Ghost PTO, the recorded input-copying case, and the 2026-10-01 command-like cleanup case were not found in the repository search on 2026-10-24. Keep these cases pending. Do not reconstruct them from issue summaries. Their absence blocks final quality acceptance, not local implementation.

## Baseline

On 2026-10-24 this Mac (macOS Darwin 27.0, Xcode 27.1 build 27A9275) passed 202 unit tests on iPhone 18 Pro (iOS 27.0). The opt-in live model suite was excluded by its existing environment gate. Physical-device output, usefulness, and latency remain unmeasured.
