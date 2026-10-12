import 'package:flutter/material.dart';

import '../onboarding_motion.dart';

/// Duolingo-style chunky button: solid face, darker bottom edge,
/// presses down onto the edge when tapped.
class ChunkyButton extends StatefulWidget {
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
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  static const double _height = 54;
  static const double _depth = 5;
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.enabled;
    final face = enabled ? scheme.primary : scheme.surfaceContainerHighest;
    final edge = enabled
        ? HSLColor.fromColor(scheme.primary)
              .withLightness(
                (HSLColor.fromColor(scheme.primary).lightness - 0.16)
                    .clamp(0.0, 1.0),
              )
              .toColor()
        : scheme.outlineVariant;
    final fg = enabled ? scheme.onPrimary : scheme.onSurfaceVariant;
    final pressed = _down && enabled;
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      onTap: enabled ? widget.onTap : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: () => _set(false),
        onTap: enabled ? widget.onTap : null,
        child: SizedBox(
          height: _height + _depth,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _height,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: edge, borderRadius: radius),
                ),
              ),
              AnimatedPositioned(
                duration: onbMotion(context, const Duration(milliseconds: 70)),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                top: pressed ? _depth : 0,
                height: _height,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: face, borderRadius: radius),
                  child: Center(
                    child: widget.loading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: scheme.onPrimary,
                            ),
                          )
                        : Text(
                            widget.label.toUpperCase(),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
