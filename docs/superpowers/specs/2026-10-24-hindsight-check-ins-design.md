# Hindsight check-ins

Status: **Full design approved by Geoff on 2026-10-24. Implementation plan and native execution approved. Production activation remains separate.**
Date: 2026-10-24
Working name: **Hindsight**. Final customer name and price remain open.

## Intent

Help someone record what they would repeat or change about a decision. Keep this separate from how well the decision turned out. The value is a history the person can inspect across decisions without generated interpretation.

Geoff approved the shift from feelings tracking to this question: **Would you approach this the same way?** The four answers are **Same approach / Different approach / Different choice / Not sure**. An optional note records what the person would keep or change. Existing outcome tracking, revisits, notes, timelines, and free Look Back remain free.

Generated Reflection is outside the proposed paid promise. Local and PCC evaluations failed its quality gate. Retain the existing work and evidence on the branch; do not delete it, activate it, or require more model testing to use Hindsight.

## Why this exists: Ghost PTO

Geoff described taking Ghost PTO because work felt overwhelming. He expected disengaging for a day to help. He instead felt guilty during the day, then further behind and less motivated the next day. Asked whether he would repeat the choice, he said he would approach it differently.

His alternative was a partial day: monitor at intervals, triage critical items, answer items that take little effort, and leave less urgent items for his usual catch-up before 7 AM. This is his proposed approach, not an app recommendation or a proven better outcome.

The check-in can record **Different approach** and retain that explanation in his own words. Do not infer a numerical outcome rating, a diagnosis, regret about taking any break, or a causal lesson from this conversation. This qualitative example does not recover the exact missing Ghost PTO records required by the separate model evaluation.

## First version

### Record at an existing review

Add an optional Hindsight section to Mark Outcome and Revisit. Do not add a field at initial decision logging, a new tab, a separate check-in schedule, or another journal.

Prompt: **Would you approach this the same way?**

- **Same approach:** I would make this choice and approach it the same way.
- **Different approach:** I would keep the underlying choice but change how I carried it out.
- **Different choice:** I would choose another course, including not doing it.
- **Not sure:** I have considered it and do not yet know.

No answer is selected by default. A revisit starts unanswered; do not copy the previous answer into a new check-in. Allow clearing an answer before saving. Skipping is different from selecting Not sure. Neither answering nor writing a note is required to save the existing outcome or revisit.

Use the existing optional review/revisit note. Do not add a second text field. When an answer is selected, offer **What would you keep or change?** as the note prompt. Keep the existing free note usable without an answer or purchase. Feelings can be recorded in the person's own words; do not add a mood/confidence scale or classify feelings from text.

The outcome and hindsight answer are independent. A Good outcome may have Different choice. A Bad outcome may have Same approach. Do not treat either pairing as an error or require an explanation.

### Read the history

Show the first review's answer beside its outcome and note on Decision Detail. Show each later answer beside its own dated revisit. Keep the full notes readable. New revisits append their own answer and do not replace earlier answers.

When showing the latest recorded hindsight outside the full timeline, show its date. If a later revisit skipped hindsight, retain the prior recorded answer with its original date; do not present it as a new answer. Do not call a change between answers an improvement or deterioration.

No new historical editing or backfill flow in this version. Existing notes/editing behavior stays intact. An existing decision can gain a new hindsight answer through its next ordinary revisit. Cancellation must not change any saved field.

### Review across decisions

Add one Hindsight section to existing Insights. It contains counts for the four answers and a list of the corresponding decisions. Tapping a count filters that list. Each row opens the current decision and identifies the dated check-in used. Keep the normal free Insights cards intact.

Count each decision once, using its most recent nonempty hindsight answer. Pair that answer with the outcome recorded at that same first review or revisit. Do not pair an old answer with a newer unanswered revisit's outcome. Use the existing chronology rules; resolve equal dates consistently with the existing recorded order.

Show **N decisions with a recorded answer**. Exclude unanswered decisions from these counts. Count explicit Not sure separately. With none, explain that answers can be added during a review or revisit. With one, show that record without a minimum-history lock or a pattern claim. Counts and lists must reconcile after additions, deletion, import, and relaunch.

Allow the person to filter the list by the five existing outcome ratings as well as a hindsight answer. This supports examining Good outcomes with Different choice, or Bad outcomes with Same approach, without inventing an emotional meaning. Filters combine; an empty intersection explains that no recorded check-ins match. Do not add a score, personality label, advice, inferred theme, causal statement, category ranking, or another chart in this version.

## Approved purchase boundary

The proposed paid capability is structured hindsight capture plus the new cross-decision review. The four-choice field alone is not the full purchase promise. Existing free notes, reviews, revisits, timelines, analytics, and Look Back remain usable without a purchase.

Author's proposed implementation choice: reuse the existing one-time entitlement and honor existing owners. Keep Hindsight availability separate from the disabled generated-Reflection feature gate. Do not require Apple Intelligence, PCC, internet, or a newer OS than the app's existing iOS 18.6 minimum for local Hindsight use.

For nonowners, show a compact optional purchase entry at existing review/revisit moments. In Insights, show the purchase entry when no saved answers exist; when answers exist, open their counts and list without a paywall and offer purchase only for new capture. Open the purchase sheet only when a purchase entry is tapped. Never open it on Save, on launch, or as a requirement to record an outcome. Show a clearly labeled authored example using structured answers and notes; promise no generated reading.

Author's access proposals: saved answers and their notes remain readable and exportable after an ownership loss or while StoreKit is unavailable. This includes the Hindsight counts, outcome filters, and decision list whenever saved answers exist, including answers restored from an import. Reading existing data does not require a new purchase. Require verified ownership only to add a new structured answer. Use StoreKit's locally verified ownership state for offline use. A previously verified owner can add answers without a fresh network check on each Save; recheck ownership through the normal StoreKit lifecycle and block new answers after confirmed revocation. A transient StoreKit failure must not erase known ownership. A person with no verified ownership remains unable to add an answer while verification is pending or unavailable. Do not add a separate license server. Do not block free saves while ownership is pending or unavailable. An ownership loss before Save must not silently discard a selected answer: retain the draft, explain the issue, and allow restoring ownership or clearing the optional answer before saving the free review. No deletion on refund.

This is a commercial proposal, not evidence of willingness to pay. Final package name, price, and App Store/IAP copy require Geoff's review. Do not change App Store Connect, submit, upload, or activate a purchase from this document.

## Data and implementation boundaries

Author's proposed data choice: add optional Codable/Equatable hindsight values to the existing first outcome record and each Revisit. Reuse `Decision.reflection` and `Revisit.note` for the person's writing. Keep the existing JSON store; do not add a second hindsight store, SwiftData, CloudKit, or dependencies.

Old files decode missing hindsight fields as no answer. Do not infer or backfill from ratings, notes, category, generated readings, or Contrition sentiment. Preserve answers in decision export/import and full backup/restore; a legacy import leaves them absent. Reject unknown answer values as an unreadable import rather than silently dropping recorded data. Import replacement and Delete All retain their existing confirmation behavior and include these fields.

Hindsight must not affect expected/actual outcomes, prediction accuracy, optimism bias, outcome charts, reminder dates, decision completion, or generated-reading eligibility. The new review pairs recorded facts only. No model call or network dependency is part of capture, history, or calculation.

Builder choices: exact Swift type/file names, view composition, and layout within these existing screens. Follow the project design contract: Dynamic Type, VoiceOver labels and selected state, stable IDs, theme-aware controls, generous targets, and readable full labels. Do not import Contrition's screens, scheduling, persistence, or drift classifier.

## Acceptance before activation

- Distinguish Same approach, Different approach, Different choice, and Not sure in concrete examples. Confirm Geoff can record Ghost PTO without marking the underlying need for a break as rejected.
- Save first-review and multiple revisit answers with notes; reopen after relaunch. Later answers and skipped check-ins must preserve earlier history and dates.
- Demonstrate both Good + Different choice and Bad + Same approach without inferred advice. Verify the cross-decision view uses the outcome from the selected answer's event, one record per decision.
- Keep omitted answers outside the denominator and explicit Not sure inside it. Verify equal dates, clearing a draft, cancellation, empty lists, mixed filters, deletion, and imported legacy/current data.
- Verify free logging, reviews, revisits, notes, Insights, and Look Back with no purchase. Check purchase/Restore, ownership loss during a draft, and continued reading/export of saved answers.
- Check the running app at default and largest text in light/dark mode on iPhone 18 Pro (iOS 27.0). Check VoiceOver and real-phone usability separately. Automated correctness does not establish paid value.
- Review a small set of real decision histories with Geoff. Confirm the cross-decision view reveals useful distinctions beyond the existing notes and timeline. Do not activate a paid package solely because counts and persistence pass tests.

## Approval and release boundary

Geoff approved this complete design, including the paid boundary, existing-entitlement reuse, offline ownership, retained reading access, and the author-selected data/review rules. Geoff approved the [implementation plan](../plans/2026-10-24-hindsight-check-ins.md) for native execution. November 2.1.0 is the prior target, not a new delivery commitment. Final name, price, and sale copy can be settled before release; they do not authorize app or App Store changes now.
