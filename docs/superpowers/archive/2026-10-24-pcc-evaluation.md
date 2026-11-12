# PCC evaluation plan

**Goal:** Compare PCC at moderate reasoning with the frozen local Reflection baseline. Geoff approved execution on 2026-10-24.
**Scope:** Evaluation only. Keep production paid Reflection disabled. Preserve prompts, schemas, source selection, digest limits, validation, and saved data.

- [x] Fast-forward `dev/paid-reflection` to the entitlement commit. Confirm the SDK API and runtime access on iPhone 18 Pro (iOS 27.0).
- [x] Add a Debug-only responder seam to `LiveReflectionService`. Keep the PCC implementation in the test target. Check that provider failures do not fall back to local generation.
- [x] Capture all 36 frozen cases at moderate reasoning. Save raw and displayed output from each response, source keys, prompts, timing, errors, availability, and quota. Keep lifecycle cases separate.
- [x] Score against the frozen baseline. Run regular tests and a Release build. Update evaluation and project tracking docs. Commit locally; leave push and merge to Geoff.

Physical-device quality, missing real-note regressions, and purchase acceptance remain separate gates. Do not expand the input budget in this comparison.
