# Hindsight Review Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans or superpowers:subagent-driven-development after Geoff approves execution. Steps use checkbox syntax for tracking.

**Goal:** Make Hindsight a useful collection of the user's recorded lessons for 2.1.0.

**Architecture:** Extend the existing calculated review entries with the decision's current category. Show the note belonging to the same recorded event as the answer and outcome. Combine a category filter with the existing answer and outcome filters; keep counts and access rules unchanged.

**Tech Stack:** SwiftUI, Swift 6, Swift Testing, existing JSON store and StoreKit entitlement.

**Spec:** `docs/superpowers/specs/2026-10-24-hindsight-check-ins-design.md`, amended by Geoff's 2026-10-27 approval of the direction in this plan. The category filter and visible notes extend that spec's original review scope.

## Global Constraints

- Support iOS 18.6 and later. Add no dependency or model generation.
- Preserve free reviews, notes, timelines, Insights, and Look Back. Keep saved Hindsight readable after ownership loss.
- Count each decision once using its last recorded answer and that event's date, outcome, and note. A skipped revisit does not replace the pair.
- Use the decision's current category, including after an edit. Do not persist a new historical category.
- Show full notes without truncation. Treat nil, empty, and whitespace-only notes as absent; show `No note recorded.`
- Keep all four answer counts across all recorded decisions. Filters affect the list, not those counts. Clear filters resets all three filters.
- Do not infer themes, advice, causation, or a claim of paid value. Keep generated Reflection disabled.
- Use only iPhone 18 Pro (iOS 27.0) for simulator verification. Preserve and restore simulator data and settings.

## Review Focus

- A skipped revisit must not replace the earlier answer, outcome, date, or note.
- An answered revisit with no note must not display an older event's note.
- A category edit or imported replacement must update review entries without stale results.
- Combined filters, empty intersections, and Clear filters must behave consistently while counts stay global.
- Long and whitespace-only notes must remain readable at accessibility sizes; saved entries must remain readable without ownership.

## Task 1: Preserve event notes and filter by category

**Files:** Modify `Offshoots/Hindsight/HindsightEntry.swift`, `HindsightSummary.swift`, `HindsightReviewFilter.swift`; test `OffshootsTests/HindsightSummaryTests.swift` and `HindsightReviewTests.swift`.

**Interfaces:** Add `let category: DecisionCategory` to `HindsightEntry`. Extend `HindsightSummary.filtered(_:answer:outcome:category:)` with `category: DecisionCategory?`. Add `var category: DecisionCategory?` to `HindsightReviewFilter`; `apply(to:)` passes all three filters.

- [ ] Add tests for a first answer followed by a skipped revisit, an answered revisit without a note, and a last recorded backdated revisit. Assert the selected event's answer, date, outcome, and note remain paired. Assert entries carry the decision's current category after an edit or replacement.
- [ ] Add tests for combined answer, outcome, and category filters, a zero-result intersection, clearing all filters, and unchanged global answer counts. Run the focused tests and confirm the new category assertions fail before implementation.
- [ ] Populate `category` from `Decision.category` in both entry paths. Apply the optional category predicate alongside the existing predicates. Update existing callers for the new argument.
- [ ] Run `DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -only-testing:OffshootsTests/HindsightSummaryTests -only-testing:OffshootsTests/HindsightReviewTests test`. Confirm both suites pass.
- [ ] Commit the data and filter changes.

## Task 2: Put notes and category filtering in the review

**Files:** Modify `Offshoots/Hindsight/HindsightDecisionRow.swift` and `HindsightReviewView.swift`; create `Offshoots/Hindsight/HindsightCategoryFilter.swift`.

**Interfaces:** `HindsightCategoryFilter` takes `@Binding var selection: DecisionCategory?`. Use a native menu like `HindsightOutcomeFilter`; label it `Category`, offer `All categories` and all six existing categories, and expose the selected value to accessibility.

- [ ] Show each entry's current category, answer, recorded date, outcome, and complete event note in its existing navigation row. Display `No note recorded.` for nil or whitespace-only notes; preserve the user's original nonempty text. Keep the decision destination and dated context.
- [ ] Add the category menu beside the existing outcome filter. Make `Clear filters` visible when any of the three filters is active. Keep count buttons global and describe that filters affect the list.
- [ ] Run the focused tests from Task 1 and the project build: `DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'generic/platform=iOS Simulator' build`. Confirm both pass.
- [ ] On iPhone 18 Pro (iOS 27.0), use backed-up and restored fixture data to inspect default and largest text in light and dark. Check a long note, no note, a skipped revisit, all three filters together, empty results, Clear filters, row navigation, and saved reading without ownership. Capture screenshots. Check accessibility labels and reading order; report spoken VoiceOver separately if not performed.
- [ ] Commit the UI changes after checks pass.

## Task 3: Review value and close out

**Files:** Update `README.md`, `CHANGELOG.md`, `DECISIONS.md`, `TODO.md`, and `docs/hindsight-evaluation.md` to reflect verified behavior and remaining gates.

- [ ] Review the complete diff for event pairing, category changes, free access, and Dynamic Type. Fix related findings and rerun affected checks.
- [ ] Review several real decision histories with Geoff, including the Ghost PTO examples. Ask whether the collection helps him find a useful lesson; do not treat correct counts as paid-value acceptance.
- [ ] Record actual test and simulator evidence and unresolved phone, VoiceOver, offline ownership, sandbox purchase, copy, and release gates. Do not activate, upload, merge to `main`, or push without separate authorization.
- [ ] Commit the documentation closeout.
