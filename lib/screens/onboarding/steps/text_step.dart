import 'package:flutter/material.dart';

import '../widgets/step_scaffold.dart';

/// Name / roll step: one large line with an underline, no box around it.
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
    final scheme = Theme.of(context).colorScheme;
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
          cursorColor: scheme.primary,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onSubmit(),
        ),
      ),
    );
  }
}
