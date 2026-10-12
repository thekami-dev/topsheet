import 'package:flutter/material.dart';

import '../../../core/motion.dart';
import '../onboarding_motion.dart';

/// Segmented progress bar: one segment per form step.
class StepBar extends StatelessWidget {
  final int current;
  final int total;

  const StepBar({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dur = onbMotion(context, Motion.standard);
    return Semantics(
      label: 'Step ${current + 1} of $total',
      child: Row(
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                child: AnimatedContainer(
                  duration: dur,
                  curve: Motion.standardCurve,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= current
                        ? scheme.primary
                        : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
