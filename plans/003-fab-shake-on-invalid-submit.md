# 003 — Shake the FAB on failed validation

- **Status**: DONE
- **Commit**: no-git (repo has no `.git`; verify against current file contents instead)
- **Severity**: MEDIUM (feedback gap — the only submit-failure signal today is a snackbar the user can miss)
- **Category**: Feedback
- **Estimated scope**: 1 file (`lib/screens/home_screen.dart`), ~50 line change — converts `_GenerateFab` from `StatelessWidget` to `StatefulWidget`

## Problem

When `_generatePdf()` fails validation, the only on-screen feedback is a
haptic + a `SnackBar` — the FAB itself, which the user just pressed and is
looking at, gives no visual signal. Error text does appear on the offending
fields, but the form may be scrolled such that none of them are visible.

`lib/screens/home_screen.dart:178-188` — current (`_generatePdf`, failure
path):

```dart
Future<void> _generatePdf() async {
    _syncTextFields();
    setState(() {});
    if (!_validate()) {
      setState(() {});
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in the highlighted fields')),
      );
      return;
    }
    setState(() => _fabState = _FabState.generating);
    ...
```

`lib/screens/home_screen.dart:465` — call site:

```dart
floatingActionButton: _GenerateFab(state: _fabState, onPressed: _generatePdf),
```

`lib/screens/home_screen.dart:471-513` (approx) — current `_GenerateFab`,
today a `StatelessWidget`:

```dart
class _GenerateFab extends StatelessWidget {
  final _FabState state;
  final VoidCallback onPressed;

  const _GenerateFab({required this.state, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final tier = motionTierOf(context);
    final label = switch (state) {
      _FabState.idle => 'Generate PDF',
      _FabState.generating => 'Generating…',
      _FabState.done => 'Saved',
    };
    final icon = switch (state) {
      _FabState.idle => const Icon(Icons.picture_as_pdf_outlined, key: ValueKey('idle')),
      _FabState.generating => const SizedBox(
          key: ValueKey('spin'),
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      _FabState.done => const Icon(Icons.check_rounded, key: ValueKey('done')),
    };
    return FloatingActionButton.extended(
      onPressed: state == _FabState.idle ? onPressed : null,
      icon: AnimatedSwitcher(
        duration: tier == MotionTier.reduced ? Motion.fast : Motion.standard,
        reverseDuration: Motion.fast,
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: icon,
      ),
      label: AnimatedSwitcher(
        duration: Motion.fast,
        child: Text(label, key: ValueKey(label)),
      ),
    );
  }
}
```

## Target

A one-shot horizontal shake, triggered by a nonce counter the parent bumps
on every failed validation (a plain `int` increment is the simplest signal
that reliably fires even if the user fails validation twice in a row without
the value otherwise changing). The shake decays as 3 damped oscillations
using this repo's own spring helper, `appleSpring()` from
`lib/core/motion.dart`, kept skippable entirely under `MotionTier.reduced`
since it's pure decoration — the snackbar and haptic already carry the
information.

### 1. `_HomeScreenState` — add and bump a shake nonce

`lib/screens/home_screen.dart`, inside `_HomeScreenState` (near the existing
`_fabState`/`_showHint` fields around line 45):

```dart
_FabState _fabState = _FabState.idle;
int _fabShakeSignal = 0;
bool _showHint = false;
```

In `_generatePdf()`, inside the `if (!_validate())` branch, add one line
that bumps the counter alongside the existing haptic/snackbar:

```dart
if (!_validate()) {
      setState(() {});
      HapticFeedback.heavyImpact();
      setState(() => _fabShakeSignal++);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in the highlighted fields')),
      );
      return;
    }
```

(Both `setState` calls can be merged into one `setState(() { _fabShakeSignal++; })` — the existing empty `setState(() {})` right above exists to re-render error text after `_validate()` mutates `_errors`; folding the counter bump into that same call is fine and slightly tidier: `setState(() => _fabShakeSignal++);` replacing the plain `setState(() {});`.)

### 2. Call site — pass the signal down

`lib/screens/home_screen.dart:465`:

```dart
floatingActionButton: _GenerateFab(
  state: _fabState,
  onPressed: _generatePdf,
  shakeSignal: _fabShakeSignal,
),
```

### 3. `_GenerateFab` — convert to `StatefulWidget`, react to `shakeSignal`

Replace the whole class with:

```dart
class _GenerateFab extends StatefulWidget {
  final _FabState state;
  final VoidCallback onPressed;
  final int shakeSignal;

  const _GenerateFab({required this.state, required this.onPressed, required this.shakeSignal});

  @override
  State<_GenerateFab> createState() => _GenerateFabState();
}

class _GenerateFabState extends State<_GenerateFab> with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController = AnimationController.unbounded(vsync: this, value: 0);

  @override
  void didUpdateWidget(_GenerateFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeSignal != oldWidget.shakeSignal) {
      final tier = motionTierOf(context);
      if (tier == MotionTier.reduced) return;
      _shakeController.animateWith(
        SpringSimulation(appleSpring(damping: 0.35, response: 0.4), 0, 0, 800),
      );
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = motionTierOf(context);
    final label = switch (widget.state) {
      _FabState.idle => 'Generate PDF',
      _FabState.generating => 'Generating…',
      _FabState.done => 'Saved',
    };
    final icon = switch (widget.state) {
      _FabState.idle => const Icon(Icons.picture_as_pdf_outlined, key: ValueKey('idle')),
      _FabState.generating => const SizedBox(
          key: ValueKey('spin'),
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      _FabState.done => const Icon(Icons.check_rounded, key: ValueKey('done')),
    };
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) => Transform.translate(
        // A decaying spring driven with initial velocity settles back to 0;
        // sin() turns that decay into a few left-right oscillations instead
        // of a one-directional slide.
        offset: Offset(6 * _shakeController.value.clamp(-1, 1) * _shakeDamp(_shakeController.value), 0),
        child: child,
      ),
      child: FloatingActionButton.extended(
        onPressed: widget.state == _FabState.idle ? widget.onPressed : null,
        icon: AnimatedSwitcher(
          duration: tier == MotionTier.reduced ? Motion.fast : Motion.standard,
          reverseDuration: Motion.fast,
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: icon,
        ),
        label: AnimatedSwitcher(
          duration: Motion.fast,
          child: Text(label, key: ValueKey(label)),
        ),
      ),
    );
  }
}
```

**This `Transform.translate` approach using the raw spring value directly is
a placeholder — it needs a real decaying-sine implementation, not
`.clamp(-1,1)` arithmetic that doesn't actually oscillate.** Use this
simpler, correct implementation instead of the sketch above:

```dart
class _GenerateFabState extends State<_GenerateFab> with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void didUpdateWidget(_GenerateFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeSignal != oldWidget.shakeSignal &&
        motionTierOf(context) != MotionTier.reduced) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  static double _offsetFor(double t) {
    // 3 decaying half-cycles: +1 → -0.6 → +0.3 → 0, eased out.
    if (t >= 1) return 0;
    final decay = 1 - t;
    return math.sin(t * math.pi * 3) * decay;
  }

  @override
  Widget build(BuildContext context) {
    // ...unchanged label/icon switch statements from current code...
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) => Transform.translate(
        offset: Offset(8 * _offsetFor(_shakeController.value), 0),
        child: child,
      ),
      child: FloatingActionButton.extended(
        // ...unchanged...
      ),
    );
  }
}
```

Add `import 'dart:math' as math;` to the top of `home_screen.dart` (check
first — `math` may already be imported elsewhere in the file; if so, don't
duplicate the import).

This uses a plain `AnimationController` + `Curves`-free `sin()` decay rather
than `appleSpring()`/`SpringSimulation`, because a shake is a fixed,
short, self-terminating flourish — not a value that needs to track a
continuously-changing gesture target (which is what springs in this
codebase are reserved for, e.g. `Pressable`'s press/release states in
`lib/widgets/pressable.dart`). Total duration 260ms — comfortably inside the
100–300ms UI budget for feedback moments.

## Repo conventions to follow

- `motionTierOf(context)` + `MotionTier.reduced` gating: the exact same
  pattern already used in `_GenerateFab`'s existing `AnimatedSwitcher`
  duration (`tier == MotionTier.reduced ? Motion.fast : Motion.standard`)
  a few lines above in the same class.
- `Motion` constants and `MotionTier` enum both live in
  `lib/core/motion.dart`, already imported in `home_screen.dart`.
- The nonce-counter-to-trigger-a-one-shot-animation pattern doesn't exist
  elsewhere in this repo yet — this plan establishes it. Keep the field
  name (`_fabShakeSignal`) and the `didUpdateWidget` comparison
  (`widget.shakeSignal != oldWidget.shakeSignal`) exactly as specified so
  future shakes/toasts can copy the same shape.

## Steps

1. Add `import 'dart:math' as math;` to the top of
   `lib/screens/home_screen.dart` (skip if `dart:math` is already imported).
2. Add `int _fabShakeSignal = 0;` next to `_FabState _fabState =
   _FabState.idle;` in `_HomeScreenState`.
3. In `_generatePdf()`'s `if (!_validate())` block, change the second
   `setState(() {});` to `setState(() => _fabShakeSignal++);` (the first
   `setState(() {});` immediately after `_syncTextFields()` stays
   untouched — it belongs to a different code path and isn't part of this
   plan).
4. Update the `floatingActionButton:` call site (~line 465) to pass
   `shakeSignal: _fabShakeSignal`.
5. Convert `_GenerateFab` to `StatefulWidget` per the corrected
   implementation in Target (the second code block — use the `sin()`-decay
   version, not the first sketch). Keep the existing `label`/`icon` `switch`
   statements and the `FloatingActionButton.extended` body byte-for-byte
   identical to current code; only wrap it in the new `AnimatedBuilder` +
   `Transform.translate`, and move the `state`/`onPressed` references to
   `widget.state`/`widget.onPressed` since they're now instance fields on
   the `State` class, not the widget itself.

## Boundaries

- Do NOT change `_FabState` enum, `_validate()`'s field-by-field logic, or
  anything in the success path (`_FabState.generating` → `_FabState.done`).
- Do NOT add a new package dependency — `sin()` comes from `dart:math`
  (stdlib), `AnimationController`/`AnimatedBuilder` from Flutter SDK.
- Do NOT use `appleSpring()`/`SpringSimulation` for this — per Target,
  those are reserved in this codebase for gesture-tracking interruptible
  motion (see `lib/widgets/pressable.dart`), not fixed one-shot flourishes.
- Do NOT make the shake loop or repeat — it must run once per
  `shakeSignal` bump and settle back to `Offset.zero`.
- If `_generatePdf()` or `_GenerateFab` have drifted from the code quoted
  above, STOP and report the mismatch instead of improvising.

## Verification

- **Mechanical**: `flutter analyze` — expect "No issues found!". `flutter
  build apk --debug` — expect a successful build.
- **Feel check**: run the app, leave every field empty, tap "Generate PDF":
  - Confirm the FAB visibly shakes left-right 2-3 times over roughly a
    quarter second, then settles dead center — no residual offset, no
    jitter.
  - Tap "Generate PDF" again immediately (same failure) — confirm the
    shake retriggers cleanly from the start rather than looking frozen or
    glitching (this is why the plan uses `.forward(from: 0)`, which
    restarts even mid-animation).
  - Fill in all fields correctly and submit — confirm no shake occurs on a
    successful submit (only the existing spinner → check morph should
    play).
  - In DevTools' Animations panel, set playback to 10% and confirm the
    motion is a clean decaying oscillation (three visible peaks shrinking
    toward center), not a single lurch or a jump.
  - Toggle Android's "Remove animations" accessibility setting (or system
    `disableAnimations`) and confirm the shake is fully skipped (FAB stays
    still) — the snackbar and haptic still fire regardless, since those
    are untouched by this plan.
- **Done when**: `flutter analyze` is clean, the shake plays once per failed
  submit and settles cleanly, and it's fully suppressed under reduced
  motion.
