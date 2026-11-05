import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../core/motion.dart';
import '../data/recall_store.dart';
import 'create_screen.dart';
import 'settings_screen.dart';

enum _FileAction { open, share, download, edit, delete }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  bool _searching = false;
  String _query = '';
  final _searchCtrl = TextEditingController();
  final _monthFmt = DateFormat('MMMM yyyy');
  final _dayFmt = DateFormat('dd MMM, hh:mm a');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchCtrl.clear();
        _query = '';
      }
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.trim().isEmpty) return _all;
    final q = _query.trim().toLowerCase();
    return _all.where((e) {
      final name = (e['name'] as String? ?? '').toLowerCase();
      return name.contains(q);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final entry in _filtered) {
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

  Future<void> _showPreview(Uint8List bytes, String name) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PdfPreviewPage(bytes: bytes, name: name),
      ),
    );
  }

  Future<void> _onAction(_FileAction action, Map<String, dynamic> entry) async {
    final path = entry['path'] as String;
    final name = entry['name'] as String? ?? 'Topsheet';

    if (action == _FileAction.edit) {
      _openCreate(initialData: entry['formData'] as Map<String, dynamic>?);
      return;
    }
    if (action == _FileAction.delete) {
      await _confirmDelete(path, name);
      return;
    }

    final bytes = await _readPdf(path);
    if (bytes == null || !mounted) return;
    switch (action) {
      case _FileAction.open:
        await _showPreview(bytes, name);
      case _FileAction.share:
        await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
      case _FileAction.download:
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

  PopupMenuItem<_FileAction> _menuItem(
    _FileAction value,
    List<List<dynamic>> icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem<_FileAction>(
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

  Widget _buildRow(Map<String, dynamic> entry) {
    final scheme = Theme.of(context).colorScheme;
    final name = entry['name'] as String? ?? 'Topsheet';
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedPdf01,
          size: 20,
          color: scheme.onPrimaryContainer,
        ),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(_dateLabel(entry)),
      trailing: PopupMenuButton<_FileAction>(
        tooltip: 'More',
        icon: HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical, size: 20),
        onSelected: (a) => _onAction(a, entry),
        itemBuilder: (_) => [
          _menuItem(_FileAction.open, HugeIcons.strokeRoundedView, 'Open'),
          _menuItem(_FileAction.share, HugeIcons.strokeRoundedShare01, 'Share'),
          _menuItem(
            _FileAction.download,
            HugeIcons.strokeRoundedDownload01,
            'Download',
          ),
          _menuItem(_FileAction.edit, HugeIcons.strokeRoundedEdit02, 'Edit'),
          const PopupMenuDivider(),
          _menuItem(
            _FileAction.delete,
            HugeIcons.strokeRoundedDelete02,
            'Delete',
            color: scheme.error,
          ),
        ],
      ),
      onTap: () => _onAction(_FileAction.open, entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final grouped = _grouped;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: AnimatedSwitcher(
          duration: Motion.fast,
          child: _searching
              ? SearchBar(
                  key: const ValueKey('search'),
                  controller: _searchCtrl,
                  autoFocus: true,
                  hintText: 'Search topsheets',
                  elevation: const WidgetStatePropertyAll(0),
                  constraints: const BoxConstraints(minHeight: 48),
                  onChanged: (v) => setState(() => _query = v),
                  trailing: [
                    if (_query.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear',
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                )
              : const Text('Topsheet', key: ValueKey('title')),
        ),
        actions: [
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search',
            icon: HugeIcon(
              icon: _searching
                  ? HugeIcons.strokeRoundedArrowLeft01
                  : HugeIcons.strokeRoundedSearch01,
            ),
            onPressed: _toggleSearch,
          ),
          if (!_searching)
            IconButton(
              tooltip: 'Settings',
              icon: HugeIcon(icon: HugeIcons.strokeRoundedSettings01),
              onPressed: _openSettings,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : grouped.isEmpty
          ? _EmptyState(hasQuery: _query.isNotEmpty)
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                96 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: [
                for (final month in grouped.keys) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: Text(
                      month,
                      style: textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  Card.filled(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final entry in grouped[month]!) _buildRow(entry),
                      ],
                    ),
                  ),
                ],
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

class _PdfPreviewPage extends StatelessWidget {
  final Uint8List bytes;
  final String name;

  const _PdfPreviewPage({required this.bytes, required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () =>
                Printing.sharePdf(bytes: bytes, filename: '$name.pdf'),
            icon: HugeIcon(icon: HugeIcons.strokeRoundedShare01),
          ),
          IconButton(
            tooltip: 'Download',
            onPressed: () => Printing.layoutPdf(
              onLayout: (_) async => bytes,
              name: '$name.pdf',
              dynamicLayout: false,
            ),
            icon: HugeIcon(icon: HugeIcons.strokeRoundedDownload01),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) async => bytes,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        useActions: false,
        previewPageMargin: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 22,
        ),
        maxPageWidth: 680,
        scrollViewDecoration: BoxDecoration(color: scheme.surface),
        pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        loadingWidget: const Center(child: CircularProgressIndicator()),
        allowSharing: false,
        allowPrinting: false,
        pdfFileName: '$name.pdf',
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: hasQuery
                  ? HugeIcons.strokeRoundedSearch01
                  : HugeIcons.strokeRoundedPdf01,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No matching topsheets' : 'No topsheets yet',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              hasQuery
                  ? 'Try a different search'
                  : 'Tap Create to make your first one',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
