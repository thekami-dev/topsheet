import 'package:flutter/material.dart';

import '../widgets/step_scaffold.dart';

/// Name / roll step: a single Material 3 outlined text field.
class TextStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String hint;
  final TextEditingController controller;
  final TextCapitalization capitalization;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  const TextStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.controller,
    required this.capitalization,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: title,
      subtitle: subtitle,
      child: Align(
        alignment: Alignment.topCenter,
        child: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: capitalization,
          textInputAction: TextInputAction.next,
          style: Theme.of(context).textTheme.titleMedium,
          decoration: InputDecoration(labelText: hint),
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onSubmit(),
        ),
      ),
    );
  }
}
