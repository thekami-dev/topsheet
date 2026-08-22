import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// How much motion the app should render this frame.
///
/// `reduced` fires when the OS accessibility flag asks for it, or when we
/// measure sustained jank at runtime (weak devices) — in both cases we fall
/// back to plain cross-fades instead of springs so the UI never feels
/// laggy.
enum MotionTier { full, reduced }

/// Samples real frame timings and downgrades [tier] if the device can't
/// keep up. This is the only signal-source for "low end device" — no
/// device-model allowlist, because actual frame time is what the user
/// feels.
class PerformanceMonitor {
  PerformanceMonitor._() {
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static final PerformanceMonitor instance = PerformanceMonitor._();

  final ValueNotifier<MotionTier> tier = ValueNotifier(MotionTier.full);

  int _jankStreak = 0;
  int _smoothStreak = 0;

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final totalMs = t.totalSpan.inMicroseconds / 1000;
      final janky = totalMs > 32; // missed a 30fps-equivalent budget
      if (janky) {
        _jankStreak++;
        _smoothStreak = 0;
      } else {
        _smoothStreak++;
        _jankStreak = 0;
      }
      if (_jankStreak >= 6 && tier.value == MotionTier.full) {
        tier.value = MotionTier.reduced;
      } else if (_smoothStreak >= 120 && tier.value == MotionTier.reduced) {
        // Long clean run — device caught up (or the janky screen is gone).
        tier.value = MotionTier.full;
      }
    }
  }
}

/// Resolves the effective [MotionTier] for the current frame, folding in
/// the OS-level "reduce motion" accessibility setting.
MotionTier motionTierOf(BuildContext context) {
  if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
    return MotionTier.reduced;
  }
  return PerformanceMonitor.instance.tier.value;
}

/// Apple-style spring constants translated to Flutter's [SpringDescription].
/// mass=1, and stiffness/damping derived so "response" behaves like the
/// WWDC parameter (time-to-settle), with a damping *ratio* controlling
/// overshoot.
SpringDescription appleSpring({double damping = 1.0, double response = 0.4}) {
  final stiffness = math.pow(2 * math.pi / response, 2).toDouble();
  final dampingCoefficient = damping * 2 * math.sqrt(stiffness);
  return SpringDescription(mass: 1, stiffness: stiffness, damping: dampingCoefficient);
}

/// Standard durations, kept short — a spring's *feel* comes from damping,
/// this only bounds the fallback cross-fade used at [MotionTier.reduced].
class Motion {
  static const fast = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);

  static const standardCurve = Curves.easeOutCubic;
}
