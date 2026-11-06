import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Looks like an outlined text field but opens a picker when tapped.
/// Shows a spinner while [loading] and an error under the field when
/// [errorText] is set.
class PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String? disabledHint;
  final String? errorText;
  final bool enabled;
  final bool loading;
  final List<List<dynamic>>? icon;
  final VoidCallback onTap;

  const PickerField({
    super.key,
    required this.label,
    required this.value,
    this.disabledHint,
    this.errorText,
    this.enabled = true,
    this.loading = false,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading;
    // suffixIcon is forced to at least 48x48, so the icon sits inside
    // padding (14 + 20 + 14) instead of being stretched to 48.
    final Widget suffix = Padding(
      padding: const EdgeInsets.all(14),
      child: loading
          ? const CircularProgressIndicator(strokeWidth: 2)
          : HugeIcon(
              icon: icon ?? HugeIcons.strokeRoundedArrowDown01,
              size: 20,
            ),
    );
    return Semantics(
      button: true,
      enabled: active,
      label: '$label, ${value ?? 'not selected'}',
      excludeSemantics: true,
      onTap: active ? onTap : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: active ? onTap : null,
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            labelText: label,
            helperText: enabled ? null : disabledHint,
            errorText: errorText,
            enabled: enabled,
            suffixIcon: suffix,
          ),
          child: Text(value ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
