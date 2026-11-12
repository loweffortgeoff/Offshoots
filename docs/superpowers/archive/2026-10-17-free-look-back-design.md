# Free Look Back for 2.0.0

Approved by Geoff on 2026-10-17. Supersedes the paid Look Back and 2.0 Reflection release decisions. Historical plans stay in place.

## Release contract
- Ship 2.0.0 with free Look Back on every supported device (iOS 18.6+). Keep counts, Expected/Turned out bars, and the existing calculated headline.
- Show the card before Expected Outcome. Below two marked decisions in the category, show the existing count-to-go message. Otherwise show the result immediately, with Copy and no generation or Refresh.
- Count every marked decision in the selected category. Compare the prediction with the first recorded outcome; revisits never change this comparison. Keep the five-decision headline minimum, strict majority, and lead of two.
- Hide Patterns, generated decision reflections, Clean Up Note, paywalls, and Reflection Settings in production. Skip model availability and StoreKit setup. Keep the implementation and tests for 2.1.0.
- Preserve personal reflection notes, outcomes, revisits, reminders, and import/export. No storage migration.

## Listing and docs
- Replace the paid Reflection promise with free Look Back in the 2.0 listing and active release notes. Check current marketing screenshots and capture instructions for paid content.
- Keep the existing IAP for November; do not submit or promote it with 2.0. Stop before archive, upload, submission, or Geoff's physical-device tests.
- Put the paid upgrade in the November 2026 2.1.0 cycle. Keep free Look Back free in 2.1.0. No exact week is assigned.

## November quality gate
- Use the 2026-10-17 groceries, Ghost PTO, More Ghost PTO, email, and Look Back examples as acceptance cases. Resolve outcome contradictions, changed comparisons, copied input, unsupported connections, and invented repetition.
- Score 30–50 varied cases, including real notes, sparse groups, revisits, long histories, and command-like text, on physical devices. Require zero factual/meaning reversals or prompt leaks and at least 90% useful, supported eligible outputs. Measure a target of 95% completing within 10 seconds; provide a bounded wait and recovery path.
- Explain data requirements before purchase. Demonstrate paid generated text rather than the free charts. Keep ownership visible during model unavailability and preserve useful output on failure.
- Include Clean Up Note only after its meaning-preservation gate passes. App Intents, Siri/Spotlight, widgets, sync, and saved monthly reviews are outside this cycle.

## Handoff
Run unit tests and a Release build. Inspect the app on iPhone 18 Pro (iOS 27.0) in light, dark, and accessibility sizes. Commit locally on dev/free-look-back. Stop at Ready for Geoff's device testing; do not merge or push.

**Handoff update (2026-10-17):** Geoff accepted build 10 on his phone and approved the local merge into main. This supersedes the device-testing stop above. Push and release actions remain separate.
