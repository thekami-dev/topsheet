import 'package:flutter/material.dart';

import '../../../data/departments.dart';
import '../../../models/institute.dart';
import '../widgets/pick_row.dart';
import '../widgets/search_field.dart';
import '../widgets/step_scaffold.dart';

class DepartmentStep extends StatefulWidget {
  final Institute? institute;
  final Department? selected;
  final ValueChanged<Department> onSelect;

  const DepartmentStep({
    super.key,
    required this.institute,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<DepartmentStep> createState() => _DepartmentStepState();
}

class _DepartmentStepState extends State<DepartmentStep> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final all = (widget.institute?.departments ?? [])
        .map(departmentByCode)
        .whereType<Department>()
        .toList();
    // Only worth showing a search box when the list is long.
    final showSearch = all.length > 5;
    final q = showSearch ? _query.trim().toLowerCase() : '';
    final filtered = q.isEmpty
        ? all
        : all.where((d) {
            return d.longName.toLowerCase().contains(q) ||
                d.shortName.toLowerCase().contains(q) ||
                d.code.toString().contains(q);
          }).toList();
    return StepScaffold(
      title: 'Your department?',
      subtitle: 'Loads the right subjects, saved for offline use.',
      child: all.isEmpty
          ? Text(
              'No departments listed for this institute yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          : Column(
              children: [
                if (showSearch) ...[
                  SearchField(
                    hint: 'Search department',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No matches',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final d = filtered[i];
                            return PickRow(
                              title: d.longName,
                              subtitle: '${d.shortName} \u00b7 Code ${d.code}',
                              selected: widget.selected?.code == d.code,
                              onTap: () => widget.onSelect(d),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
