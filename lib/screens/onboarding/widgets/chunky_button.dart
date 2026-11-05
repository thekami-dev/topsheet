import 'package:flutter/material.dart';

import '../../../core/motion.dart';

/// Full-width primary action: a Material 3 filled button.
/// (Name kept so existing call sites compile; it is no longer "chunky".)
class ChunkyButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const ChunkyButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: enabled && !loading ? onTap : null,
        // While loading keep the filled look instead of the greyed-out one.
        style: loading
            ? FilledButton.styleFrom(
                disabledBackgroundColor: scheme.primary,
                disabledForegroundColor: scheme.onPrimary,
              )
            : null,
        child: AnimatedSwitcher(
          duration: Motion.fast,
          child: loading
              ? SizedBox(
                  key: const ValueKey('spin'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: scheme.onPrimary,
                  ),
                )
              : Text(label, key: ValueKey(label)),
        ),
      ),
    );
  }
}
