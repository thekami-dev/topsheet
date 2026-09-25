import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';

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

  Future<void> _showPreview(Uint8List bytes, String name) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (ctx, anim, secAnim) => FadeTransition(
          opacity: anim,
          child: _PdfPreviewPage(bytes: bytes, name: name),
        ),
      ),
    );
  }

  Future<void> _showActions(Map<String, dynamic> entry, Offset tapPosition) async {
    final path = entry['path'] as String;
    final name = entry['name'] as String? ?? 'Topsheet';
    final scheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;

    const menuWidth = 232.0;
    const itemHeight = 46.0;
    const headerHeight = 46.0;
    const menuHeight = headerHeight + itemHeight * 5 + 12;

    double left = tapPosition.dx - menuWidth + 24;
    double top = tapPosition.dy - 12;
    if (left < 16) left = 16;
    if (left + menuWidth > screenSize.width - 16) {
      left = screenSize.width - menuWidth - 16;
    }
    if (top + menuHeight > screenSize.height - 16) {
      top = screenSize.height - menuHeight - 16;
    }
    if (top < 16) top = 16;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim, secAnim) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secAnim, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: anim,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(color: Colors.black.withValues(alpha: 0.18)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: ScaleTransition(
                scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                alignment: Alignment.topRight,
                child: FadeTransition(
                  opacity: anim,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: menuWidth,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(ctx).textTheme.labelLarge,
                            ),
                          ),
                          Divider(height: 1, color: scheme.outlineVariant),
                          _MenuAction(
                            icon: Icons.visibility_outlined,
                            label: 'Open',
                            onTap: () async {
                              Navigator.pop(ctx);
                              final bytes = await File(path).readAsBytes();
                              if (!mounted) return;
                              _showPreview(bytes, name);
                            },
                          ),
                          _MenuAction(
                            icon: Icons.share_rounded,
                            label: 'Share',
                            onTap: () async {
                              Navigator.pop(ctx);
                              final bytes = await File(path).readAsBytes();
                              await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
                            },
                          ),
                          _MenuAction(
                            icon: Icons.download_rounded,
                            label: 'Download',
                            onTap: () async {
                              Navigator.pop(ctx);
                              final bytes = await File(path).readAsBytes();
                              await Printing.layoutPdf(
                                onLayout: (_) async => bytes,
                                name: '$name.pdf',
                                dynamicLayout: false,
                              );
                            },
                          ),
                          _MenuAction(
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                            onTap: () {
                              Navigator.pop(ctx);
                              final formData = entry['formData'] as Map<String, dynamic>?;
                              _openCreate(initialData: formData);
                            },
                          ),
                          _MenuAction(
                            icon: Icons.delete_rounded,
                            label: 'Delete',
                            color: scheme.error,
                            onTap: () async {
                              Navigator.pop(ctx);
                              final file = File(path);
                              if (await file.exists()) await file.delete();
                              await RecallStore.instance.removeRecentPdf(path);
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final grouped = _grouped;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: _searching ? 4 : 20,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: _searching
              ? Container(
                  key: const ValueKey('search-field'),
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 19,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          cursorColor: scheme.primary,
                          cursorWidth: 1.6,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            isDense: true,
                            isCollapsed: true,
                            hintText: 'Search topsheets…',
                            hintStyle: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: scheme.onSurfaceVariant),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                      if (_query.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Pressable(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 17,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : Text(
                  'Topsheet',
                  key: const ValueKey('title'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
        ),
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
                            onTap: (pos) => _showActions(entry, pos),
                            onLongPress: (pos) => _showActions(entry, pos),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.45),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openCreate,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final String name;
  final String dateLabel;
  final void Function(Offset position) onTap;
  final void Function(Offset position) onLongPress;

  const _FileRow({
    required this.name,
    required this.dateLabel,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Offset lastTapPosition = Offset.zero;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => lastTapPosition = d.globalPosition,
      onTap: () => onTap(lastTapPosition),
      onLongPressStart: (d) => onLongPress(d.globalPosition),
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

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuAction({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color ?? scheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
            },
            icon: const Icon(Icons.share_rounded),
          ),
          IconButton(
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (_) async => bytes,
                name: '$name.pdf',
                dynamicLayout: false,
              );
            },
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) async => bytes,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        useActions: false,
        scrollViewDecoration: BoxDecoration(color: scheme.surfaceContainerHighest),
        pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
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
