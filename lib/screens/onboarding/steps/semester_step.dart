import 'package:flutter/material.dart';

import '../../../models/topsheet_data.dart' show semesters;
import '../widgets/step_scaffold.dart';

class SemesterStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const SemesterStep({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Current semester?',
      subtitle:
          'Pre-selected when you create a Topsheet. You can change it each time.',
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in semesters)
              ChoiceChip(
                label: Text(s),
                selected: selected == s,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                onSelected: (_) => onSelect(s),
              ),
          ],
        ),
      ),
    );
  }
}
