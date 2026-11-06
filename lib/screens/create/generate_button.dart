import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/motion.dart';
import 'create_widgets.dart' show createMotion;

enum GenState { idle, generating, done }

/// Full-width Generate button: idle -> spinner -> check, with a shake when
/// the form has errors.
class GenerateButton extends StatefulWidget {
  final GenState state;
  final VoidCallback onPressed;
  final int shakeSignal;

  const GenerateButton({
    super.key,
    required this.state,
    required this.onPressed,
    required this.shakeSignal,
  });

  @override
  State<GenerateButton> createState() => _GenerateButtonState();
}

class _GenerateButtonState extends State<GenerateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void didUpdateWidget(GenerateButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduced =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        motionTierOf(context) == MotionTier.reduced;
    if (widget.shakeSignal != oldWidget.shakeSignal && !reduced) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  static double _offsetFor(double t) {
    // 3 decaying half-cycles, settling back to 0 by t=1.
    if (t >= 1) return 0;
    final decay = 1 - t;
    return math.sin(t * math.pi * 3) * decay;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = switch (widget.state) {
      GenState.idle => 'Generate PDF',
      GenState.generating => 'Creating PDF\u2026',
      GenState.done => 'Saved',
    };
    final Widget icon = switch (widget.state) {
      GenState.idle => HugeIcon(
        key: const ValueKey('idle'),
        icon: HugeIcons.strokeRoundedPdf01,
        size: 20,
        color: scheme.onPrimary,
      ),
      GenState.generating => SizedBox(
        key: const ValueKey('spin'),
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: scheme.onPrimary,
        ),
      ),
      GenState.done => HugeIcon(
        key: const ValueKey('done'),
        icon: HugeIcons.strokeRoundedTick02,
        size: 20,
        color: scheme.onPrimary,
      ),
    };
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(8 * _offsetFor(_shake.value), 0),
        child: child,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: widget.state == GenState.idle ? widget.onPressed : null,
          // Keep the filled look while generating instead of greying out.
          style: FilledButton.styleFrom(
            disabledBackgroundColor: scheme.primary,
            disabledForegroundColor: scheme.onPrimary,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: createMotion(context, Motion.standard),
                reverseDuration: createMotion(context, Motion.fast),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: icon,
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: createMotion(context, Motion.fast),
                child: Text(label, key: ValueKey(label)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
