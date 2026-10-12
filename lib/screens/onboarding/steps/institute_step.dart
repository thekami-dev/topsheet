import 'package:flutter/material.dart';

import '../../../models/institute.dart';
import '../widgets/list_skeleton.dart';
import '../widgets/load_notices.dart';
import '../widgets/pick_row.dart';
import '../widgets/search_field.dart';
import '../widgets/step_scaffold.dart';

String? _instituteSubtitle(Institute i) {
  final parts = <String>[
    if (i.code != null && i.code!.isNotEmpty) 'Code ${i.code}',
    if (i.address != null && i.address!.isNotEmpty) i.address!,
  ];
  return parts.isEmpty ? null : parts.join(' \u00b7 ');
}

class InstituteStep extends StatefulWidget {
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  final List<Institute> institutes;
  final Institute? selected;
  final ValueChanged<Institute> onSelect;

  const InstituteStep({
    super.key,
    required this.loading,
    required this.failed,
    required this.onRetry,
    required this.institutes,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<InstituteStep> createState() => _InstituteStepState();
}

class _InstituteStepState extends State<InstituteStep> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.institutes
        : widget.institutes.where((i) {
            return i.name.toLowerCase().contains(q) ||
                (i.code ?? '').toLowerCase().contains(q) ||
                (i.address ?? '').toLowerCase().contains(q);
          }).toList();

    final Widget body;
    if (widget.loading) {
      body = const ListSkeleton();
    } else if (widget.failed) {
      body = LoadFailed(onRetry: widget.onRetry);
    } else if (widget.institutes.isEmpty) {
      body = NotListedNotice(scheme: scheme);
    } else {
      body = Column(
        children: [
          SearchField(
            hint: 'Search institute',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: filtered.length + 1,
              itemBuilder: (context, i) {
                if (i == filtered.length) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 16),
                    child: NotListedNotice(scheme: scheme),
                  );
                }
                final inst = filtered[i];
                return PickRow(
                  title: inst.name,
                  subtitle: _instituteSubtitle(inst),
                  selected: widget.selected?.id == inst.id,
                  onTap: () => widget.onSelect(inst),
                );
              },
            ),
          ),
        ],
      );
    }
    return StepScaffold(
      title: 'Your institute?',
      subtitle: 'Goes in the header of every Topsheet.',
      child: body,
    );
  }
}
