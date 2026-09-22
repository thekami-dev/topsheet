import 'package:flutter/material.dart';

import '../core/motion.dart';
import 'pressable.dart';

/* Hallmark · genre: modern-minimal · macrostructure: Workbench
 * design-system: design.md · designed-as-app
 */

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

  void _select(T item) {
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final tier = motionTierOf(context);
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type to filter and pick quickly',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.06,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    autofocus: false,
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: tier == MotionTier.reduced
                  ? Duration.zero
                  : Motion.fast,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        final tile = Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 2 : 8),
                          child: Pressable(
                            pressedScale: 0.985,
                            onTap: () => _select(item),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: scheme.outlineVariant),
                              ),
                              child: ListTile(
                                title: Text(widget.labelOf(item)),
                                subtitle: widget.subtitleOf != null
                                    ? Text(widget.subtitleOf!(item))
                                    : null,
                                trailing: Icon(
                                  Icons.north_east_rounded,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                        if (tier == MotionTier.reduced || filtered.length > 30)
                          return tile;
                        final start = (i * 0.06).clamp(0.0, 0.85);
                        final curve = Interval(
                          start,
                          1.0,
                          curve: Curves.easeOutCubic,
                        );
                        return TweenAnimationBuilder<double>(
                          key: ValueKey(i),
                          tween: Tween(begin: 0, end: 1),
                          duration:
                              Motion.standard +
                              const Duration(milliseconds: 260),
                          curve: curve,
                          builder: (context, t, child) => Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, (1 - t) * 12),
                              child: child,
                            ),
                          ),
                          child: tile,
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
