# Decisions

Newest last. Format: `## YYYY-MM-DD (title)`, then **Decision** / **Why** / **Alternative considered**.

## 2026-09-23 (Revisits keep history and can be chained)
**Decision:** A marked decision can be re-rated any number of times. Each revisit stores a date, a rating and an optional note. The first marked outcome stays in `actual` and is the basis for prediction accuracy. The latest revisit (`currentOutcome`) drives the hero, the badge and the list rows.
**Why:** Outcomes change over time. Keeping the history shows how a decision aged, and accuracy stays fair because it measures the prediction against the first result.
**Alternative considered:** Overwrite the outcome on each revisit. This loses the history and makes accuracy drift.

## 2026-09-23 (Ask for notification permission in context)
**Decision:** Do not ask at launch. Ask the first time the app schedules a reminder, including when the Settings toggle is turned on and pending reminders are rescheduled.
**Why:** The user sees why the app wants permission, at the moment it matters.
**Alternative considered:** Ask at launch. This was removed.

## 2026-09-24 (Point Zero for project docs)
**Decision:** Start CHANGELOG, DECISIONS and TODO today. Backfill only from git history and the 2026-09-23 audit doc. Do not try to rebuild older decisions.
**Why:** The history is 17 commits and the audit doc already records all recent work. A deeper dig would guess at reasons that were never written down.
**Alternative considered:** A full reconstruction from old commits.

## 2026-09-24 (Track docs/ in git)
**Decision:** `.gitignore` ignores `*.md` but makes an exception for `docs/**/*.md`.
**Why:** Plans, specs and session notes must live in git with their history.
**Alternative considered:** Force-add single files. That is easy to forget and hides new docs.
