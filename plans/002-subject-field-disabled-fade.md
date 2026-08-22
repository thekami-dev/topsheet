# 002 — Fade the Subject field's enabled/disabled state instead of snapping it

- **Status**: DONE
- **Commit**: no-git (repo has no `.git`; verify against current file contents instead)
- **Severity**: LOW
- **Category**: Missed opportunity / preventing a jarring change
- **Estimated scope**: 1 file, ~10 line change

## Problem

`_PickerField` (used for both Department and Subject) renders its enabled
state directly through `InputDecoration(enabled: enabled, ...)`. The Subject
field starts disabled (dimmed, per Material's built-in disabled color) and
the instant the user picks a Department, `enabled` flips to `true` and the
whole decorator snaps to full color with no transition — a one-time but
noticeable "teleport" the first time a user fills the form.

`lib/screens/home_screen.dart:643-681` — current:

```dart
class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool enabled;
  final String? errorText;

  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) => Pressable(
        pressedScale: 0.99,
        onTap: enabled ? onTap : null,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, enabled: enabled, errorText: errorText),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? 'Select…',
                  style: TextStyle(
                    color: value == null
                        ? Theme.of(context).hintColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
        ),
      );
}
```

Call site (unchanged, for context) at `lib/screens/home_screen.dart:344-349`:

```dart
_PickerField(
  label: 'Subject',
  value: _data.subject?.name,
  enabled: _data.department != null,
  onTap: _pickSubject,
  errorText: _errors['subject'],
),
```

## Target

Wrap the existing `InputDecorator` (keep it always logically "enabled" so
Material doesn't change its own internal color scheme) in an
`AnimatedOpacity` driven by the `enabled` flag, using the project's
`Motion.fast` token (120ms) and `Curves.easeOutCubic` — this repo's standard
entering/settling curve (see `lib/core/motion.dart`, used identically for
the FAB icon switch-in). `onTap` still gates on `enabled` so the field
remains untappable while dimmed; only the *visual* transition changes.

```dart
@override
Widget build(BuildContext context) => Pressable(
      pressedScale: 0.99,
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.5,
        duration: Motion.fast,
        curve: Curves.easeOutCubic,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, errorText: errorText),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? 'Select…',
                  style: TextStyle(
                    color: value == null
                        ? Theme.of(context).hintColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
        ),
      ),
    );
```

Note `enabled: enabled` is **removed** from `InputDecoration` — the 0.5
opacity now carries 100% of the disabled signaling, so we don't want
Material's own disabled-color logic fighting the `AnimatedOpacity` (that
would produce a double-dim, or a hard color snap underneath a smooth opacity
fade). `errorText` behavior is unaffected since it isn't tied to `enabled`.

## Repo conventions to follow

- `Motion.fast` (120ms) + `Curves.easeOutCubic` is the exact pairing already
  used for `_GenerateFab`'s `AnimatedSwitcher` `switchOutCurve` in this same
  file (`lib/screens/home_screen.dart`, `class _GenerateFab`) — reuse it
  verbatim rather than approximating a new duration.
- `Motion` lives in `lib/core/motion.dart` and is already imported at the
  top of `home_screen.dart` — no new import needed.

## Steps

1. Open `lib/screens/home_screen.dart`, locate `class _PickerField` (around
   line 643).
2. Remove `enabled: enabled` from the `InputDecoration(...)` call inside
   `build()`.
3. Wrap the `InputDecorator(...)` widget in `AnimatedOpacity(opacity: enabled
   ? 1 : 0.5, duration: Motion.fast, curve: Curves.easeOutCubic, child:
   InputDecorator(...))`, keeping every other line of the subtree (the
   `Row`, `Expanded`, `Text`, `Icon`) exactly as-is.
4. Leave `onTap: enabled ? onTap : null` on the outer `Pressable` unchanged
   — gating interactivity is separate from the opacity fade.

## Boundaries

- Do NOT change the `enabled: _data.department != null` call site in
  `home_screen.dart` (~line 345) — only `_PickerField`'s internals change.
- Do NOT touch `_TextInput`, `RecallTextField`, or any other field widget in
  this file — this plan is scoped to `_PickerField` only.
- Do NOT add a new duration/curve constant — reuse `Motion.fast` /
  `Curves.easeOutCubic`.
- Do NOT add a new package dependency (`AnimatedOpacity` is Flutter SDK).
- If `_PickerField` has drifted from the code quoted above, STOP and report
  the mismatch instead of improvising a merge.

## Verification

- **Mechanical**: `flutter analyze` — expect "No issues found!". `flutter
  build apk --debug` — expect a successful build.
- **Feel check**: run the app on a fresh form (Subject field disabled/dimmed
  at 50% opacity), tap Department, pick any department, and confirm:
  - The Subject field's dim-to-full-opacity transition is a visible fade,
    not an instant snap.
  - The field remains untappable (no picker sheet opens) until the fade
    reaches full opacity's *logical* state — i.e. `onTap` is gated by
    `enabled`, not by the animation's progress, so this should already be
    correct by construction; just confirm tapping the dimmed field before
    picking a department does nothing.
  - No double-dim artifact (the field should read as one smooth opacity
    ramp, not a color-snap-then-fade).
  - Toggle reduced-motion (Android "Remove animations" / system
    `disableAnimations`) and confirm... note `AnimatedOpacity` does not
    natively read `MotionTier` — see the note below.
- **Reduced-motion note**: unlike the picker sheet's `MotionTier`-gated
  animations, this plan does not gate on `MotionTier` explicitly. 120ms is
  short enough and opacity-only (never movement) that it's within the
  "gentler, not zero" allowance for reduced motion per this repo's own
  `core/motion.dart` doc comment on `MotionTier`. If the feel-check reveals
  this reads as unwanted motion under `prefers-reduced-motion`, wrap the
  `duration` in `motionTierOf(context) == MotionTier.reduced ? Duration.zero
  : Motion.fast` (same pattern as plan 001) as a follow-up — do not add this
  speculatively without confirming it's needed.
- **Done when**: `flutter analyze` is clean and the Subject field visibly
  fades from dimmed to full opacity on Department selection instead of
  snapping.
