# Animation plans

Source: `find-animation-opportunities` sweep, vetted against current code.
Repo has no `.git` — plans are stamped `no-git`; re-verify file:line against
current contents before executing, don't trust the commit stamp.

| # | Title | Severity | Status |
| --- | --- | --- | --- |
| [001](001-picker-empty-state-fade.md) | Fade picker sheet's "No matches" empty state | LOW | DONE |
| [002](002-subject-field-disabled-fade.md) | Fade Subject field's enabled/disabled state | LOW | DONE |
| [003](003-fab-shake-on-invalid-submit.md) | Shake FAB on failed validation | MEDIUM | DONE |

## Recommended order

003 → 001 → 002. 003 is the only MEDIUM (a real feedback gap on failed
submit); 001 and 002 are independent low-severity polish in different files
and can be done in any order, including in parallel — no shared code between
any of the three plans.

## Dependencies

None. Each plan touches a distinct widget/section:

- 001 → `lib/widgets/searchable_picker.dart` only.
- 002 → `_PickerField` in `lib/screens/home_screen.dart` only.
- 003 → `_generatePdf()` + `_GenerateFab` in `lib/screens/home_screen.dart`
  only (does not touch `_PickerField`, so safe to run alongside 002 despite
  sharing a file — different classes, no overlapping lines).
