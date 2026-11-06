import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Looks like an outlined text field but opens a picker when tapped.
class PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String? disabledHint;
  final bool enabled;
  final VoidCallback onTap;

  const PickerField({
    super.key,
    required this.label,
    required this.value,
    this.disabledHint,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: '$label, ${value ?? 'not selected'}',
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            labelText: label,
            helperText: enabled ? null : disabledHint,
            enabled: enabled,
            suffixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 20,
            ),
          ),
          child: Text(value ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
