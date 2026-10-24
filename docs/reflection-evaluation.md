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

## Local implementation evidence — 2026-10-24

Geoffrey's Mac mini runs macOS 27.0.1 (26A434) and Xcode 27.1 (27A9275). The revised local suite passes 229 tests in 31 suites on iPhone 18 Pro (iOS 27.0), with the opt-in model suite excluded from that count.

The model is available on this simulator. The first 36-case diagnostic run exposed copied individual notes: 18 of 26 labeled eligible cases returned no generated observations; seven cases returned preflight errors/abstentions. The live purchase-sample assertion failed. That baseline did not meet the paid-quality gate.

A simpler one-connection schema and short request-local references then produced the captured purchase example in `fixtures/reflection-purchase-sample.json`. The next 36-case diagnostic run completed, but also exposed command-like text being repeated. Recognizable model-control text is now omitted whole before generation; original journal records stay intact. This conservative exclusion is not proof against every instruction-like input.

Decision readings now use only their own recorded stages. Code supplies the rating timeline; the model may add one comparison between two cited stages. Saved-history access, refund/source-change request invalidation, failed writes, and coordinated backup rollback have unit evidence. Fake-output UI checks cover generation, refresh, relaunch history, evidence navigation, light/dark, and largest text. Final artifact UI review and independent code review are still pending at this entry.

Physical-device quality, cleanup meaning preservation, usefulness scores, sandbox purchase/Restore/refund, and the exact real-note regressions remain unaccepted. Production paid Reflection remains disabled. Local model results do not clear those gates.
