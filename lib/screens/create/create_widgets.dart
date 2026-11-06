import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/motion.dart';

/// Animation length that respects the OS reduce-motion flag and the app's
/// own jank-based downgrade.
Duration createMotion(BuildContext context, Duration full) {
  if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
    return Duration.zero;
  }
  return motionTierOf(context) == MotionTier.reduced ? Motion.fast : full;
}

/// Top of the form: the chosen subject (or a placeholder) and progress.
class CreateHeader extends StatelessWidget {
  final String? subject;
  final int filled;
  final int total;

  const CreateHeader({
    super.key,
    required this.subject,
    required this.filled,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final complete = filled >= total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject ?? 'New topsheet',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall,
                ),
              ),
              if (complete) ...[
                const SizedBox(width: 8),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedTick02,
                  size: 24,
                  color: scheme.primary,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            complete
                ? 'Everything is filled in. Ready to generate.'
                : '$filled of $total required fields filled',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: filled / total),
            duration: createMotion(context, Motion.standard),
            curve: Motion.standardCurve,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled group of fields with a small "2/4" or "Done" indicator.
class FormSection extends StatelessWidget {
  final String title;
  final int done;
  final int total;
  final List<Widget> children;

  const FormSection({
    super.key,
    required this.title,
    required this.done,
    required this.total,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final complete = done >= total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Row(
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(color: scheme.primary),
              ),
              const Spacer(),
              if (complete) ...[
                HugeIcon(
                  icon: HugeIcons.strokeRoundedTick02,
                  size: 16,
                  color: scheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Done',
                  style: textTheme.labelMedium?.copyWith(color: scheme.primary),
                ),
              ] else
                Text(
                  '$done/$total',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          children[i],
        ],
      ],
    );
  }
}

/// Explains why the subject list is empty, with Retry when the cause may be
/// the connection.
class SubjectNote extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const SubjectNote({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            size: 18,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
                height: 1.35,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onErrorContainer,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// One-time tip shown above the form.
class HintBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const HintBanner({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      height: 1.3,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Fill it once \u2014 ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: 'generate, preview, and share in one flow.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                size: 18,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
