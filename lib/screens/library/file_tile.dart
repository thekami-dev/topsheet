import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum FileAction { open, share, download, edit, delete }

/// One saved topsheet: tap to open, ⋮ for the other actions.
class FileTile extends StatelessWidget {
  final String name;
  final String dateLabel;
  final ValueChanged<FileAction> onAction;

  const FileTile({
    super.key,
    required this.name,
    required this.dateLabel,
    required this.onAction,
  });

  PopupMenuItem<FileAction> _item(
    FileAction value,
    List<List<dynamic>> icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem<FileAction>(
      value: value,
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: color == null ? null : TextStyle(color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedPdf01,
          size: 22,
          color: scheme.onPrimaryContainer,
        ),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(dateLabel),
      trailing: PopupMenuButton<FileAction>(
        tooltip: 'More',
        icon: HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical, size: 20),
        onSelected: onAction,
        itemBuilder: (_) => [
          _item(FileAction.open, HugeIcons.strokeRoundedView, 'Open'),
          _item(FileAction.share, HugeIcons.strokeRoundedShare01, 'Share'),
          _item(
            FileAction.download,
            HugeIcons.strokeRoundedDownload01,
            'Download',
          ),
          _item(FileAction.edit, HugeIcons.strokeRoundedEdit02, 'Edit'),
          const PopupMenuDivider(),
          _item(
            FileAction.delete,
            HugeIcons.strokeRoundedDelete02,
            'Delete',
            color: scheme.error,
          ),
        ],
      ),
      onTap: () => onAction(FileAction.open),
    );
  }
}
