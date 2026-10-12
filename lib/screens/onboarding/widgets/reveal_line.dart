import 'package:flutter/material.dart';

/// Fades [child] in while it slides up a little, between [begin] and [end]
/// of the shared intro timeline [progress] (both 0..1). Nothing tilts or
/// wobbles; the text always sits straight.
class RevealLine extends StatelessWidget {
  const RevealLine({
    super.key,
    required this.progress,
    required this.begin,
    required this.end,
    required this.child,
  });

  final Animation<double> progress;
  final double begin;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) {
        final raw = (progress.value - begin) / (end - begin);
        final v = Curves.easeOutCubic.transform(raw.clamp(0.0, 1.0));
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 16), child: child),
        );
      },
    );
  }
}
