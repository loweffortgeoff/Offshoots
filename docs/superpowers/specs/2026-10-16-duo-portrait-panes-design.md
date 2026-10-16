# Duo portrait panes: the landscape pairs, top and bottom — design

Date: 2026-10-16. Follows `docs/superpowers/specs/2026-10-16-duo-wide-panes-design.md`
(the landscape pairs). Read that spec first: this one reuses its content choices.

## Intent

On the iPhone Duo partly open in portrait, every tab fills only the top half. The
bottom half is plain background, with the tab bar floating at its foot. Geoff saw this
on the simulator after the landscape work and wants the same pairs here: the first
pane on top, the second below the fold.

Fully open, the Duo keeps the centred 600 pt column. Geoff accepts that (it looks like
an iPad).

## Goals

- Partly open portrait, Dashboard, Log, Decisions and Insights each use both halves.
  The pairs are the landscape pairs. Top is the landscape left pane. Bottom is the
  landscape right pane.

  | Tab | Top | Bottom |
  |---|---|---|
  | Dashboard | Dashboard | Detail of the selected decision |
  | Log | Form (Geoff, 2026-10-16) | "Recent in <Category>" list |
  | Decisions | List | Detail |
  | Insights | "What you decide" cards | "Outcomes" cards |

- Content, selection rules, default selection, empty states and row taps stay exactly
  as in the landscape spec. This is a layout change only.

## Non-goals

- Settings stays in one pane (top half), as in landscape.
- Fully open portrait and fully open landscape do not change.
- Closed Duo and every other iPhone do not change, in any orientation.
- No new content, no new model calls.

## Anti-goals

- Content under the fold band or under the floating tab bar.
- A half-typed Log entry lost when the Duo changes between one pane and two panes
  (same risk as landscape; same rule: the form's `@State` lives on `LogDecisionView`).
- A change on a non-foldable iPhone. The new rule needs a horizontal fold band, which
  no other device reports.

## Constraints

- Builds only with Xcode 27.1 on the Mac mini. Fold APIs stay behind
  `#available(iOS 27.1, *)`.
- Partly open portrait numbers (from the probe in CLAUDE.md): 669 x 951 pt, band at
  y 455, 40 pt tall, 20 pt margins. Each half is about 456 pt tall. The bottom half also
  loses the floating tab bar's height. The bottom pane needs a bottom inset, as the
  landscape primary pane needed a trailing inset for the rail.
- Use `FOLDPANE` debug lines to check pane edges, not pixel positions.
- Each pane scrolls on its own.
- `DecisionDetailView` does not change.

## Design

- **Vertical split.** `WidePanes` takes an axis. Horizontal (today) uses
  `.split.axes(.horizontal)`. Vertical uses `.split.axes(.vertical)`. Name and shape
  are the builder's call. Assumption to confirm on the first build: `ArrangementView`
  accepts `.vertical`.
- **Two-pane rule.** `FoldPosture` gains a way to say which axis the two panes use:
  - width ≥ 900 pt on a foldable device: horizontal panes (today).
  - `.folded(.horizontal, …)` (partly open portrait): vertical panes.
  - anything else: one pane.
  `paneFit` returns `.fill` for a screen that owns its layout in either two-pane case.
  `supportsTwoPanes(width:)` and `TwoPaneReader` change so each screen can pick the axis.
  Keep the pure logic in small functions with unit tests (as `FoldPosture` is today).
- **Screens.** Dashboard, Log, Decisions and Insights already switch between one pane
  and two. They pass the axis to `WidePanes`. No content changes.
- **Top pane.** It stops at the fold (cut at the band's top edge). The bottom pane
  starts below the band and clears the tab bar.
- **Insights titles.** One "Insights" title over the top pane. The bottom pane is
  titled "Outcomes", as in landscape.

## Build order

Branch `feature/duo-portrait-panes`. Each step is a reviewable stop. Geoff checks each
in DeviceHub (partly open portrait). Claude checks that the iPhone 18 Pro (iOS 27.0) is
unchanged.

1. **Vertical `WidePanes`, the new two-pane rule, Insights.** Confirms `.vertical`
   works and the bottom inset is right.
2. **Decisions and Dashboard.**
3. **Log.** Include the fold-and-rotate check with a half-typed entry.

## Testing

- Unit tests (Swift Testing) for the new pure rule: partly open portrait gives vertical
  panes; partly open landscape and fully open landscape give horizontal; fully open
  portrait, closed Duo and flat devices give one pane.
- Full suite on Xcode 27.1 before merge.
- iPhone 18 Pro (iOS 27.0): all four tabs unchanged from `main`, portrait and landscape.
- Duo (Geoff, DeviceHub): partly open portrait for each tab; also rotate to partly open
  landscape and back; fully open portrait unchanged.
- Dynamic Type at accessibility sizes in vertical two-pane mode.

## Left to the builder

- The shape of the axis API (enum, parameter, or two wrappers).
- The exact bottom inset and how it is read (as `WidePanes` reads the rail inset).
- Spacing and detail-pane tweaks needed at 456 pt tall, within the existing card style.
- Whether the Log form's focus and scroll position survive a layout change. Its values
  must.

## Risks

1. `.vertical` may not behave like `.horizontal` (fold placement, safe areas). Stop 1
   tests this before anything else is built.
2. The 456 pt bottom pane, minus the tab bar, is short for `DecisionDetailView`. It
   scrolls. If it feels too cramped, Geoff decides at the stop 2 review.
3. A keyboard on the Log form covers the bottom half. Accepted.
