import 'package:flutter/material.dart';

import '../../core/motion.dart';

/// Animation length that respects the OS reduce-motion flag and the app's
/// own jank-based downgrade.
Duration onbMotion(BuildContext context, Duration full) {
  if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
    return Duration.zero;
  }
  return motionTierOf(context) == MotionTier.reduced ? Motion.fast : full;
}
