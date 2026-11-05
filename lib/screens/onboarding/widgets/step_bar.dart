import 'package:flutter/material.dart';

import '../../../core/motion.dart';
import '../onboarding_motion.dart';

/// Progress through the form steps: a Material 3 linear progress bar that
/// glides to the new value.
class StepBar extends StatelessWidget {
  final int current;
  final int total;

  const StepBar({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final dur = onbMotion(context, Motion.slow);
    return Semantics(
      label: 'Step ${current + 1} of $total',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: (current + 1) / total),
        duration: dur,
        curve: Motion.standardCurve,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
