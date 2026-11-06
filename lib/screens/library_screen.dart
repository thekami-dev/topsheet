import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../data/recall_store.dart';
import 'create_screen.dart';
import 'library/file_tile.dart';
import 'library/library_empty_state.dart';
import 'library/pdf_preview_page.dart';
import 'settings_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  final _monthFmt = DateFormat('MMMM yyyy');
  final _dayFmt = DateFormat('dd MMM, hh:mm a');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await RecallStore.instance.recentPdfs();
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  Future<void> _openCreate({Map<String, dynamic>? initialData}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateScreen(initialData: initialData)),
    );
    _load();
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final entry in _all) {
      final iso = entry['generatedAt'] as String?;
      final date = iso != null ? DateTime.tryParse(iso) : null;
      final key = date != null ? _monthFmt.format(date) : 'Unknown';
      map.putIfAbsent(key, () => []).add(entry);
    }
    return map;
  }

  String _dateLabel(Map<String, dynamic> entry) {
    final iso = entry['generatedAt'] as String?;
    final date = iso != null ? DateTime.tryParse(iso) : null;
    return date != null ? _dayFmt.format(date) : '';
  }

  Future<Uint8List?> _readPdf(String path) async {
    try {
      return await File(path).readAsBytes();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open this file.")),
        );
      }
      return null;
    }
  }

  Future<void> _onAction(FileAction action, Map<String, dynamic> entry) async {
    final path = entry['path'] as String;
    final name = entry['name'] as String? ?? 'Topsheet';

    if (action == FileAction.edit) {
      _openCreate(initialData: entry['formData'] as Map<String, dynamic>?);
      return;
    }
    if (action == FileAction.delete) {
      await _confirmDelete(path, name);
      return;
    }

    final bytes = await _readPdf(path);
    if (bytes == null || !mounted) return;
    switch (action) {
      case FileAction.open:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PdfPreviewPage(bytes: bytes, name: name),
          ),
        );
      case FileAction.share:
        await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
      case FileAction.download:
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: '$name.pdf',
          dynamicLayout: false,
        );
      default:
        break;
    }
  }

  Future<void> _confirmDelete(String path, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete topsheet?'),
        content: Text('"$name" will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
    await RecallStore.instance.removeRecentPdf(path);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final grouped = _grouped;
    final bottom = 96 + MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Topsheet'),
            actions: [
              IconButton(
                tooltip: 'Settings',
                icon: HugeIcon(icon: HugeIcons.strokeRoundedSettings01),
                onPressed: _openSettings,
              ),
              const SizedBox(width: 4),
            ],
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (grouped.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: LibraryEmptyState(),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(bottom: bottom),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  for (final month in grouped.keys) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                      child: Text(
                        month,
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    for (final e in grouped[month]!)
                      FileTile(
                        name: e['name'] as String? ?? 'Topsheet',
                        dateLabel: _dateLabel(e),
                        onAction: (a) => _onAction(a, e),
                      ),
                  ],
                ]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(),
        icon: HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
        label: const Text('Create'),
      ),
    );
  }
}
