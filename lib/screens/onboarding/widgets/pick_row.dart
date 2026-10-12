import 'package:flutter/material.dart';

import '../../../core/motion.dart';
import '../../../widgets/pressable.dart';
import '../onboarding_motion.dart';

/// One list row: plain text with a hairline under it. The selected row turns
/// accent-coloured and shows a tick (its space is always reserved, so
/// nothing shifts).
class PickRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const PickRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.99,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 24,
                height: 24,
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: onbMotion(context, Motion.fast),
                  child: Icon(
                    Icons.check_rounded,
                    color: scheme.primary,
                    size: 22,
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
