import 'package:flutter/material.dart';

import '../../../core/motion.dart';
import '../../../models/topsheet_data.dart' show semesters;
import '../../../widgets/pressable.dart';
import '../onboarding_motion.dart';
import '../widgets/step_scaffold.dart';

class SemesterStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const SemesterStep({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StepScaffold(
      title: 'Current semester?',
      subtitle: 'Pre-selected when you create a Topsheet. You can change it each time.',
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: semesters.map((s) {
            final isSelected = selected == s;
            return Semantics(
              button: true,
              selected: isSelected,
              label: 'Semester $s',
              excludeSemantics: true,
              onTap: () => onSelect(s),
              child: Pressable(
                onTap: () => onSelect(s),
                child: AnimatedContainer(
                  duration: onbMotion(context, Motion.fast),
                  curve: Motion.standardCurve,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isSelected ? scheme.primary : scheme.outlineVariant,
                    ),
                  ),
                  child: Text(
                    s,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? scheme.onPrimary : scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
