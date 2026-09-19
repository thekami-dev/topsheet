import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../data/recall_store.dart';
import '../widgets/pressable.dart';
import 'create_screen.dart';
import 'settings_screen.dart';

/* Hallmark · genre: dark-premium · macrostructure: Workbench
 * design-system: design.md · designed-as-app
 */

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

  Future<void> _showActions(Map<String, dynamic> entry) async {
    final path = entry['path'] as String;
    final name = entry['name'] as String? ?? 'Topsheet';
    final scheme = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final bytes = await File(path).readAsBytes();
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: '$name.pdf',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Download'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final bytes = await File(path).readAsBytes();
                await Printing.layoutPdf(
                  onLayout: (_) async => bytes,
                  name: '$name.pdf',
                  dynamicLayout: false,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(sheetContext);
                final formData = entry['formData'] as Map<String, dynamic>?;
                _openCreate(initialData: formData);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: scheme.error),
              title: Text('Delete', style: TextStyle(color: scheme.error)),
              onTap: () async {
                Navigator.pop(sheetContext);
                final file = File(path);
                if (await file.exists()) await file.delete();
                await RecallStore.instance.removeRecentPdf(path);
                _load();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final grouped = _grouped;

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search topsheets…',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : const Text('Topsheet'),
        actions: [
          Pressable(
            onTap: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _searchCtrl.clear();
                _query = '';
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            ),
          ),
          if (!_searching)
            Pressable(
              onTap: _openSettings,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.settings_outlined),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : grouped.isEmpty
          ? _EmptyState(hasQuery: _query.isNotEmpty)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                for (final month in grouped.keys) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 12, left: 2),
                    child: Text(
                      month.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final entry in grouped[month]!) ...[
                          _FileRow(
                            name: entry['name'] as String? ?? 'Topsheet',
                            dateLabel: () {
                              final iso = entry['generatedAt'] as String?;
                              final date = iso != null
                                  ? DateTime.tryParse(iso)
                                  : null;
                              return date != null ? _dayFmt.format(date) : '';
                            }(),
                            onTap: () => _showActions(entry),
                            onLongPress: () => _showActions(entry),
                          ),
                          if (entry != grouped[month]!.last)
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: scheme.outlineVariant,
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final String name;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FileRow({
    required this.name,
    required this.dateLabel,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                size: 20,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery ? Icons.search_off_rounded : Icons.description_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery ? 'No matching topsheets' : 'No topsheets yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              hasQuery
                  ? 'Try a different search'
                  : 'Tap + to create your first one',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
