# 001 — Fade the picker sheet's "No matches" empty state in/out

- **Status**: DONE
- **Commit**: no-git (repo has no `.git`; verify against current file contents instead)
- **Severity**: LOW
- **Category**: Missed opportunity / preventing a jarring change
- **Estimated scope**: 1 file, ~15 line change

## Problem

In the searchable picker bottom sheet, the list-vs-empty-state swap is an
instant conditional render with no transition. As the user types a query
that matches nothing (or clears back to matches), the list and the "No
matches" text teleport in and out.

`lib/widgets/searchable_picker.dart:88-107` — current:

```dart
Expanded(
  child: filtered.isEmpty
      ? const Center(child: Text('No matches'))
      : ListView.builder(
          controller: scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final item = filtered[i];
            final tile = Pressable(
              pressedScale: 0.98,
              onTap: () => _select(item),
              child: ListTile(
                title: Text(widget.labelOf(item)),
                subtitle: widget.subtitleOf != null ? Text(widget.subtitleOf!(item)) : null,
              ),
            );
            // Stagger only when the device can afford it and the
            // list is short enough that a stagger is felt, not endured.
            if (tier == MotionTier.reduced || filtered.length > 30) return tile;
            ...
          },
        ),
),
```

## Target

Wrap the ternary's two branches in an `AnimatedSwitcher` using a fade only
(no scale/slide — this is a low-severity polish item, not a hero moment).
Use the project's own `Motion.fast` token (120ms, defined in
`lib/core/motion.dart`) and `Curves.easeOutCubic` for both directions since
this is a same-place content swap, not an entering/exiting surface with a
different asymmetry need.

```dart
Expanded(
  child: AnimatedSwitcher(
    duration: tier == MotionTier.reduced ? Duration.zero : Motion.fast,
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeOutCubic,
    transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
    child: filtered.isEmpty
        ? const Center(key: ValueKey('empty'), child: Text('No matches'))
        : ListView.builder(
            key: const ValueKey('list'),
            controller: scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              // ...unchanged...
            },
          ),
  ),
),
```

Note the two `ValueKey`s (`'empty'` / `'list'`) — `AnimatedSwitcher` needs
distinct keys on its direct child to detect the swap; without them it won't
animate at all.

## Repo conventions to follow

- Duration/curve tokens live in `lib/core/motion.dart` (`Motion.fast`,
  `Motion.standard`, `Motion.standardCurve`). Do not invent a new duration
  constant — reuse `Motion.fast`.
- `MotionTier` gating pattern: this file already computes `final tier =
  motionTierOf(context);` near the top of `build()` (see
  `lib/widgets/searchable_picker.dart` around line 46) and branches on
  `tier == MotionTier.reduced` for the row stagger a few lines below this
  edit. Follow the same pattern — under `MotionTier.reduced`, use
  `Duration.zero` so the reduced-motion path is an instant swap, matching
  how the row entrance is skipped entirely in reduced mode a few lines down.

## Steps

1. Open `lib/widgets/searchable_picker.dart`. Confirm the `tier` variable
   already exists in scope at the empty/list ternary (it's used a few lines
   below for the stagger gate — reuse the same variable, don't recompute).
2. Replace the plain ternary at lines 88-107 (`child: filtered.isEmpty ? ...
   : ListView.builder(...)`) with the `AnimatedSwitcher` shown in Target,
   keeping the entire `ListView.builder` body (including the stagger logic
   inside `itemBuilder`) unchanged — only the outer wrapper and the two
   `ValueKey`s are new.
3. Verify the `Center` and `ListView.builder` are now the *direct* children
   of `AnimatedSwitcher` (not wrapped in anything else) so the widget-type +
   key diff triggers correctly.

## Boundaries

- Do NOT touch the row stagger logic inside `itemBuilder` (the
  `Interval`/`TweenAnimationBuilder` block) — out of scope, already correct.
- Do NOT touch `lib/widgets/recall_text_field.dart`, `home_screen.dart`, or
  any other file.
- Do NOT add a new duration or curve constant — reuse `Motion.fast` /
  `Curves.easeOutCubic`.
- Do NOT add a new package dependency (`AnimatedSwitcher` is Flutter SDK).
- If the ternary at 88-107 has drifted from what's quoted above (e.g. the
  `isEmpty` branch text changed), STOP and report the mismatch instead of
  guessing at the new structure.

## Verification

- **Mechanical**: `flutter analyze` — expect "No issues found!". `flutter
  build apk --debug` — expect a successful build (matches the last known-good
  state of this repo).
- **Feel check**: run the app, open any searchable picker (e.g. Department),
  type a query with no matches, then delete it back to a match. Confirm:
  - The "No matches" text fades in rather than popping in instantly.
  - The list fades back in when a match reappears, without the fade
    fighting the existing row-stagger entrance (the fade should be near-
    instant at 120ms; the stagger is the more noticeable motion).
  - Toggle Android's "Remove animations" accessibility setting (or system
    `disableAnimations`) and confirm the swap becomes instant with no fade —
    this exercises the `MotionTier.reduced` branch.
  - In DevTools' Animations panel (or by eye at normal speed — 120ms is
    short enough that slow-motion isn't necessary here), confirm no visible
    flash of both states overlapping.
- **Done when**: `flutter analyze` is clean, the fade is visible at normal
  speed, and it disappears under reduced-motion.
