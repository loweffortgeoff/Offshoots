# Paid Reflection for 2.1.0

Status: Approved by Geoff on 2026-10-24. Proceed to implementation planning. Execution of the implementation plan remains a separate approval.

## Purpose

Help the user notice supported connections across decisions and understand how a decision changed over time. The paid promise is: “See what repeats across your decisions, and how your view changes over time.”

November 2026 remains the target. No exact week is set. Quality acceptance controls release readiness.

## Agreed product scope

- **Patterns with evidence:** Find specific connections across separate decisions. Compare across categories when the notes support it. Let the user open each supporting decision.
- **How a decision aged:** Connect the original prediction, first outcome, and later revisits. Describe changes without inventing causes.
- **Generate on request:** The user starts generation and refresh. Do not generate at launch, after edits, or while the user logs a decision. Free Look Back already serves the moment before a decision.
- **Saved reflections:** Retain dated generated readings and their supporting evidence. Later edits and revisits must not silently rewrite earlier readings.
- **Clean Up Note:** Keep it as a bonus, subject to meaning-preservation acceptance. It is not a main reason to buy.
- Keep the existing one-time purchase. Free Look Back stays free on all supported devices.

## Explicit decision reversal

Saved generated reflections supersede the “not saved” rule in `../archive/2026-09-30-reflection-design.md` and the matching historical implementation and purchase notes. Preserve those documents as history.

The 2026-10-17 free Look Back contract still applies. User-written `Decision.reflection` remains a separate journal field. Saving generated readings does not authorize scheduled monthly reviews.

## Reading and generation contract

Patterns compare notes and outcomes from distinct decisions. Multiple notes or revisits on one decision count as one supporting decision. A shared category or a similar rating alone does not establish a meaningful connection.

Each claimed recurring connection needs at least two distinct supporting decisions. This is a minimum, not proof of a general rule. State the limited scope. Do not turn a few examples into “always,” a personality label, advice, or a causal claim.

A decision reflection can stand alone when there is enough recorded history to describe a change. Other decisions are optional evidence, not a required section. Omit unsupported sections. With sparse or unrelated records, explain the limit instead of filling space.

Code determines counts, rating comparisons, chronology, and record selection. The model describes supplied evidence. Preserve decision identity, note stage, dates, and rating context through the digest and output. Retain exact supporting excerpts rather than asking the model to invent citations.

Separate prediction accuracy from later outcome changes. Use the first outcome for the prediction comparison. Describe revisits in date order with their actual ratings. A later improvement does not make an incorrect first prediction a match.

Explain which records were read and any sampling limits. Do not claim to have read the entire journal when context limits require a subset. Fit prompts to the available context without silently cutting away a negation or comparison.

## Interaction and storage details

Geoff approved these engineering proposals with the full spec on 2026-10-24.

- Keep Patterns on Insights and the decision reading on Decision Detail. Add Generate for the first reading and Refresh for a new reading. Provide dated history from those surfaces without a new top-level tab.
- Save each successful, validated reading automatically. Refresh creates a new dated entry. It never replaces an earlier entry. Keep older readings accessible after relaunch.
- Store a stable reading ID, kind, generation date, generated content, records-read scope, and the source snapshot needed to inspect each claim. Retain source decision IDs for navigation and the relevant original text, ratings, and dates for historical evidence.
- Use a small local JSON store for generated readings. Keep `decisions.json` compatible with existing fixtures and decision exports. Do not add a database, sync service, or third-party dependency.
- Compare current source records with the saved source snapshot. Mark a reading when its source changed or disappeared. For Patterns, also indicate when new eligible decisions exist. Show saved text until the user requests a new reading.
- A source link opens the current decision. Label the retained evidence as “At generation” when it differs. If a decision was deleted, keep the saved evidence and explain that the live record is unavailable.
- Let the user delete an individual saved reading with confirmation. Warn that deleting a decision leaves excerpts in saved readings. Delete All Decisions must also clear saved readings and state this in its confirmation.
- Include saved readings in a separate full-backup export/import path. Preserve existing decision-only array imports and exports. A full restore replaces both collections with confirmation. A decision-only replacement clears saved readings after an explicit warning. No silent data loss or orphaned current-record links.
- Saved readings remain readable if the model becomes unavailable. Keep ownership and Restore visible. Do not require another generation request to view saved content.
- Treat saved readings as the user's local history. Keep them readable and deletable after a refund or loss of entitlement. Require current ownership for new generation, refresh, and Clean Up Note. Verify this distinction in refund tests.
- Before purchase, show a fixed example produced by the model from clearly labeled sample records and accepted in evaluation. Do not generate a live preview from the user's journal. Explain data and device requirements beside the example.

Clean Up Note remains a preview that requires acceptance before it changes a note. It does not create a saved generated reading.

## Failure and availability

Keep free charts and saved readings visible during generation, failure, and model unavailability. Show progress and provide cancellation. Use a bounded wait and a useful retry path. A cancelled, failed, unsupported, or empty result must not create a saved reading.

Report persistence failures. Do not label a result Saved until the write succeeds. Preserve older saved readings when refresh or persistence fails. Keep user journal text intact.

Restore saved readings locally without querying the model. Prompt/model changes affect future generations only. A new reading may differ from an earlier one; do not alter history to hide that difference.

## Draft acceptance examples

These expected outputs are authored examples from `../../fixtures/reflection-notes.json`. The fixture is synthetic and has planted themes. These examples are not measured model results or sufficient release evidence.

### A. A supported connection across two decisions

Evidence: “Upgrade to the new laptop” mentions a sale ending that night and buying in a hurry. “Sign up for the annual gym plan” mentions a price increase and signing on the spot. Both predict Good and first record Bad.

Accept: “The laptop purchase and gym plan both mention a price deadline and an immediate commitment. Both first outcomes were worse than you expected.” Link both decisions.

Reject: “You always regret rushed purchases,” “Sales pressure caused these outcomes,” or a claim supported by only one decision with several notes.

### B. A decision that improved without matching its prediction

Evidence: “Say yes to leading the launch project” predicts Very Good. Its first outcome is Bad on July 8, with two lost weekends. Its August 7 revisit is Neutral and says it settled after handing off reporting.

Accept: “You expected leading the launch project to go very well. You first rated it Bad after losing two weekends. A month later, you rated it Neutral and wrote that it settled once you handed off the reporting.”

Reject: “It worked out as expected,” an invented Good rating, or an asserted cause beyond what the writer recorded.

### C. Sparse and unrelated evidence

One decision with three notes can support its own reading. It cannot establish a recurring pattern across decisions. Several unrelated records must not produce a forced theme. A correct insufficient-evidence response passes this case.

### D. Cross-category evidence

The laptop purchase and launch-project commitment are in Money and Work. Both original notes describe an immediate commitment. Both first outcomes are worse than predicted.

Accept a narrowly stated connection about those two records with both sources. Reject a claim that the work decision involved a price deadline, or that acting quickly caused either outcome. Category boundaries must not block a supported connection.

### E. Saved evidence after a change

Generate and save a reading. Edit a supporting note or add a revisit. Reopen the saved reading after relaunch. Its original text, date, and evidence remain intact. It indicates changed source data. Refresh saves a separate entry.

Repeat with a deleted source, cancelled refresh, failed save, model unavailability, full backup/restore, and decision-only import. Verify the proposed retention and deletion rules before release.

## Evaluation and release gate

- Define 30–50 scored cases before fixes. Include real notes, sparse groups, unrelated decisions, cross-category connections, revisits, long histories, supported languages, and command-like text.
- Include the recorded Groceries, Ghost PTO, More Ghost PTO, and input-copying failures. Obtain their exact source records before scoring. Do not reconstruct missing notes from titles or summaries.
- Require zero factual reversals, meaning changes, or prompt leaks. Require at least 90% of eligible outputs to add a specific, supported observation. Score correct abstention separately from eligible useful output.
- Inspect raw and displayed output. Check source attribution and distinct-decision support. Filtering must not conceal a feature that routinely returns nothing.
- Measure on physical devices. Target 95% of requests within 10 seconds. Record hardware, OS, model availability, failures, cancellations, and timeouts. These are targets, not current results.
- Check saved-history persistence, source changes/deletions, backup compatibility, failure recovery, Dynamic Type, VoiceOver, and purchase/Restore/refund behavior. Use iPhone 18 Pro (iOS 27.0) explicitly for simulator work.
- Before purchase, demonstrate actual generated text and explain device/model and data requirements. Exclude free Look Back from the paid feature promise. Prepare listing, IAP metadata, and screenshots after quality acceptance.

## Scope boundary and handoff

No scheduled generation, monthly reviews, reminders for generated readings, advice, scoring, personality labels, widgets, App Intents, Siri/Spotlight, feelings tracking, or sync/backup service belongs to this cycle. Local file backup of the new saved data is part of persistence, not cloud sync.

The six existing roadmap phases remain. Add saved history, evidence navigation, and persistence acceptance within the observation and recovery phases. Keep unrelated free Optimism and Duo work separate.

Plan the evaluation and implementation in bounded chunks. App code, activation of paid features, release actions, and push are outside this documentation task. Plan: `../plans/2026-10-24-paid-reflection.md`.
