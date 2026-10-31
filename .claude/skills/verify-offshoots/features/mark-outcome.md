# Mark an outcome / revisit

## Sub-features
Mark Outcome (first result, optional note), Revisit Decision (later result with timeline), prediction result banner, delete/edit.

## How to get to it (user POV)
Dashboard "Ready to Review" row, or Decisions tab > row > detail. Detail shows `Mark Outcome` for pending decisions and `Revisit Decision` for resolved ones.

## Driving it with agent-device
Seed `screenshots`, press `Book the dentist, Health • Ready to review...` on the Dashboard, press `Mark Outcome`, pick an outcome button, optionally fill the note, press `Save Outcome`. End state: `V db "Book the dentist"` shows `actual` set (not None); Dashboard Completed +1, Pending -1. (Labels are from source; not yet driven in a proof. Report differences in this file.)

## Gotchas
- Hindsight check-in controls may appear in this form; they are optional and must not block saving unless a purchase restore is pending (`hindsightSaveBlocked`).
- Saving may schedule or cancel reminders and raise the notification prompt once.
