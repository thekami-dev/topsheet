import 'package:flutter/material.dart';

/// One word whose letters tumble in one after another, each landing with a
/// small permanent tilt so the line feels hand-set rather than typeset.
///
/// [progress] is the shared intro timeline (0..1). Letters start at
/// [begin] and are staggered by [firstIndex], so several words can read as
/// one continuous cascade.
class TwistedWord extends StatelessWidget {
  const TwistedWord({
    super.key,
    required this.word,
    required this.style,
    required this.progress,
    this.firstIndex = 0,
    this.begin = 0.58,
  });

  final String word;
  final TextStyle? style;
  final Animation<double> progress;
  final int firstIndex;
  final double begin;

  static const double _stagger = 0.013;
  static const double _span = 0.2;
  static const double _restTilt = 0.045;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final letters = word.split('');
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < letters.length; i++)
              _letter(letters[i], firstIndex + i, progress.value),
          ],
        );
      },
    );
  }

  Widget _letter(String ch, int index, double t) {
    final start = begin + index * _stagger;
    final local = ((t - start) / _span).clamp(0.0, 1.0);
    final settle = Curves.easeOutBack.transform(local);
    final side = index.isEven ? 1.0 : -1.0;
    return Opacity(
      opacity: (local * 2).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - settle) * 22 + side * 1.5 * local),
        child: Transform.rotate(
          angle: (1 - settle) * side * -0.5 + side * _restTilt * local,
          child: Text(ch, style: style),
        ),
      ),
    );
  }
}
