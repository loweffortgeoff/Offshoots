# Duo wide panes: Dashboard, Insights and Log — design

Date: 2026-10-16. Follows `docs/superpowers/archive/2026-10-07-duo-fold-layout-design.md`
("Amendable choices" 1 and 2).

## Intent

On the iPhone Duo in landscape, Dashboard, Log and Insights fill only the left half.
The right half is plain background. Geoff looked at this on the simulator and does
not like the empty half. The first fold pass held back on purpose: the spec ruled out
Dashboard and Insights splits until Geoff had seen the single-pane screens. He has now
seen them.

Goal: in wide landscape on the Duo, each of these three tabs uses both halves. Each
half has a clear purpose, and the fold sits between them. No half is plain background.

## Goals

- **Dashboard:** summary and review queue on the left, the selected decision's detail
  on the right.
- **Insights:** the cards split into two topic groups, one group per side.
- **Log:** the form on the left, recent decisions in the selected category on the right.
- The same rule as Decisions decides when a screen splits:
  `FoldPosture.supportsTwoPanes(width:)` (a foldable device, width ≥ 900 pt). This
  covers the Duo partly open in landscape and fully open in landscape.

## Non-goals

- Settings stays single-pane. (Geoff accepted this.)
- Partly open portrait (top and bottom halves) does not change. Content stays in the
  top half.
- Fully open portrait does not change (centred 600 pt column).
- Insights chart interactions (tap a category to filter a list). This is Geoff's idea
  3 in his testing notes. It is later work.
- New content or features. Log's right pane shows existing decisions with existing row
  views. It is a layout change. It is not the "Before you decide" paywall idea, and it
  adds no model call.

## Anti-goals

- Any change on a non-foldable iPhone, in any orientation. A Pro Max in landscape is
  956 pt wide and must keep the phone layout. `supportsTwoPanes` already handles this.
- Lost state when the Duo folds, unfolds or rotates. A half-typed Log entry must
  survive a change between one pane and two panes. This is the main technical risk.
  See `FoldPane.swift` (the comment above `pane(for:)`) for why a `switch` on layout
  rebuilds the view and wipes its `@State`.
- Content under the fold band.

## Constraints

- Builds only with Xcode 27.1 on the Mac mini. Fold APIs stay behind
  `#available(iOS 27.1, *)`. The app still runs on iOS 18.6.
- Reuse the Decisions pattern: `DecisionsSplitView` uses `ArrangementView` with
  `.arrangementViewStyle(.split.axes(.horizontal))`, and the system puts the fold
  between the panes. `DecisionsListView.layout(twoPanes:)` shows how a screen picks
  one layout or the other.
- A screen that builds its own two panes passes `FoldPane(ownsWideLayout: true)` in
  `ContentView`, so `FoldPane` gives it the full width.
- Each pane scrolls on its own.
- `DecisionDetailView` is not changed. It already takes a `decision`.

## Per-screen design

### Dashboard

- **Left pane:** today's Dashboard content, unchanged (header, Ready to Review,
  starter suggestions, quick stats, recent decisions).
- **Right pane:** `DecisionDetailView` for the selected decision, in its own
  `NavigationStack` (as in `DecisionsSplitView`).
- **Selection:** in two-pane mode, a tap on a row in Ready to Review or Recent
  Decisions selects that decision and shows it on the right. It does not push. The
  selected row is highlighted. In one-pane mode the rows push, as today.
- **Default selection, so the right pane is never empty:** the first Ready to Review
  decision. If none is ready, the most recent decision. If there are no decisions, a
  placeholder like the one in `DecisionsSplitView` (SF Symbol and one line of text).
- **Selection model (Claude's call):** store an explicit selected decision ID. Once a
  decision shows on the right, it stays there while it exists, even when it leaves Ready
  to Review. Example: the user marks the outcome of the default decision. The right pane
  stays on it and shows the `PredictionResultBanner`, which is the payoff of a review. It
  does not jump to the next ready decision. The default applies only when nothing is
  selected yet, or the selected decision is deleted (as `DecisionsSelection.pruned`
  does for Decisions). The highlighted row may then be on neither left-pane list. That
  is accepted.
- **Changing between one pane and two (Claude's call, simplest option):** the
  selection is not carried either way. Two panes to one: the user sees the Dashboard at
  the top, with nothing pushed. One pane to two: a pushed detail is dropped, and the
  right pane shows the stored selection or the default. Dashboard keeps its plain
  `NavigationLink` pushes and gets no navigation path. This can change after Geoff sees
  it.

### Insights

- **Left pane, "what you decide":** Overall Stats, Decision Timeline, Category
  Breakdown, Outcome Distribution.
- **Right pane, "how it turned out":** Outcome Trends, Prediction Accuracy, Optimism,
  Patterns (when it shows today).
- **No decisions:** keep one pane with `EmptyAnalyticsView`, centred across the full
  width. Builder's call: whether it centres across both halves or sits on the left.
- One navigation title, "Insights", over the left pane. The right pane has no title of
  its own.
- The card order in one-pane mode does not change.

### Log

- **Left pane:** today's Log form, unchanged.
- **Right pane:** a read-only list headed "Recent in <Category>". It shows the most
  recent decisions in the category picked in the form, newest first, up to 10. It
  updates when the user changes the category.
- **Empty category:** show the most recent decisions across all categories, headed
  "Recent Decisions". With no decisions at all, show a short placeholder.
- **Rows:** reuse `DecisionRowView`.
- **Row taps (Geoff, 2026-10-16):** a tap switches to the Decisions tab with that
  decision open, as a reminder tap does through `ContentView.openDecision`. A
  half-typed entry must survive the tab switch.
- **State:** the form's `@State` (title, notes, category, stakes, expected, review
  date) must survive a change between one pane and two panes. The builder picks how
  (for example, keep the form at a fixed position in one view tree and add or remove
  only the right pane).

## Build order

Branch `feature/duo-wide-panes`. Each step is a reviewable stop. Geoff checks each one
in DeviceHub (partly open landscape and fully open landscape), and Claude checks that
the iPhone 18 Pro (iOS 27.0) is unchanged.

1. **Insights split.** Pure layout. Also decide whether `DecisionsSplitView` becomes a
   shared two-pane helper, or each screen builds its own `ArrangementView`.
2. **Dashboard + detail.** Selection, default selection, highlight.
3. **Log + recent list.** Category filter and fallback. Test the fold-and-rotate state
   check with a half-typed entry.

## Testing

- Unit tests (Swift Testing) for the pure parts: Dashboard default selection, and the
  Log list (category filter, limit of 10, fallback when the category is empty). Put the
  logic in small pure functions, as `DecisionsSelection` does.
- Build with the Xcode 27.1. Run the full test suite before merge.
- iPhone 18 Pro (iOS 27.0): Dashboard, Log and Insights look the same as on `main`,
  in portrait and landscape.
- Duo (Geoff in DeviceHub): partly open landscape and fully open landscape for each
  screen. Use the `FOLDPANE` log lines to check pane edges.
- Dynamic Type at accessibility sizes in two-pane mode.

## Left to the builder

- Whether to generalise `DecisionsSplitView` into a shared helper.
- How the Dashboard row taps switch between push and select.
- How to keep the Log form's identity stable.
- Exact headings, placeholder symbols and spacing, within the existing card style.
- Whether focus, scroll position and the calendar's shown month survive a layout
  change in Log. The form's values must survive. They are `@State` on
  `LogDecisionView`, so they survive if the split is built inside that view's body.
- "Most recent" in Log means `store.decisions` order (newest first).
