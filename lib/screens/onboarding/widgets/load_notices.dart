import 'package:flutter/material.dart';

/// Shown when institutes couldn't be loaded and nothing is saved yet.
class LoadFailed extends StatelessWidget {
  final VoidCallback onRetry;

  const LoadFailed({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text("Couldn't load institutes", style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Check your internet connection and try again.\n'
              'Or tap Skip and finish this later in Settings.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class NotListedNotice extends StatelessWidget {
  final ColorScheme scheme;
  const NotListedNotice({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.5,
        ),
        children: const [
          TextSpan(text: "Can't find your institute? Email "),
          TextSpan(
            text: 'info@thekami.tech',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: ' or join our Discord and we\u2019ll add it.'),
        ],
      ),
    );
  }
}
