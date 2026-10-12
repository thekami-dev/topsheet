import 'package:flutter/material.dart';

import '../../../core/motion.dart';
import '../onboarding_motion.dart';

/// Placeholder rows shown while the institute list loads.
class ListSkeleton extends StatefulWidget {
  const ListSkeleton({super.key});

  @override
  State<ListSkeleton> createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<ListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (onbMotion(context, Motion.slow) == Duration.zero) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bar = scheme.surfaceContainerHighest;
    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_c.value);
          return Opacity(
            opacity: 0.55 + 0.45 * t,
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < 7; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 200 + (i % 3) * 40.0,
                          decoration: BoxDecoration(
                            color: bar,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 10,
                          width: 100,
                          decoration: BoxDecoration(
                            color: bar,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
