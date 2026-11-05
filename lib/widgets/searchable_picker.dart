import 'package:flutter/material.dart';

import '../core/motion.dart';
import 'search_field.dart';

Future<T?> showSearchablePicker<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T) labelOf,
  String Function(T)? subtitleOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _PickerSheet<T>(
      title: title,
      items: items,
      labelOf: labelOf,
      subtitleOf: subtitleOf,
    ),
  );
}

class _PickerSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final String Function(T)? subtitleOf;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    this.subtitleOf,
  });

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final reduced = motionTierOf(context) == MotionTier.reduced;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? widget.items
        : widget.items.where((item) {
            return widget.labelOf(item).toLowerCase().contains(q) ||
                (widget.subtitleOf?.call(item).toLowerCase().contains(q) ??
                    false);
          }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: textTheme.titleLarge),
                const SizedBox(height: 16),
                SearchField(
                  hint: 'Search',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: reduced ? Duration.zero : Motion.fast,
              child: filtered.isEmpty
                  ? Center(
                      key: const ValueKey('empty'),
                      child: Text(
                        'No matches',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      key: const ValueKey('list'),
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        final sub = widget.subtitleOf?.call(item);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          title: Text(widget.labelOf(item)),
                          subtitle: (sub == null || sub.isEmpty)
                              ? null
                              : Text(sub),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
