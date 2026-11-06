import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// One selectable list row (Material 3 list item). The selected row gets a
/// secondary-container background and a tick; the tick's space is always
/// reserved so nothing shifts.
class PickRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const PickRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: selected,
        selectedColor: scheme.onSecondaryContainer,
        selectedTileColor: scheme.secondaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: selected
              ? HugeIcon(
                  icon: HugeIcons.strokeRoundedTick02,
                  size: 22,
                  color: scheme.onSecondaryContainer,
                )
              : null,
        ),
        onTap: onTap,
      ),
    );
  }
}
