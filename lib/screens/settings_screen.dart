import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../data/recall_store.dart';
import '../widgets/pressable.dart';

/* Hallmark · genre: modern-minimal · macrostructure: Long Document
 * design-system: design.md · designed-as-app
 */

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _df = DateFormat('dd MMM yyyy, HH:mm');
  List<Map<String, dynamic>> _recents = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final recents = await RecallStore.instance.recentPdfs();
    if (mounted) setState(() => _recents = recents);
  }

  Future<void> _open(Map<String, dynamic> entry) async {
    final file = File(entry['path'] as String);
    if (!await file.exists()) {
      await RecallStore.instance.removeRecentPdf(entry['path'] as String);
      if (!mounted) return;
      _loadRecents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That PDF is no longer available')),
      );
      return;
    }
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  Future<void> _save(Map<String, dynamic> entry) async {
    final file = File(entry['path'] as String);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${entry['name']}.pdf',
      dynamicLayout: false,
    );
  }

  Future<void> _share(Map<String, dynamic> entry) async {
    final file = File(entry['path'] as String);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    await Printing.sharePdf(bytes: bytes, filename: '${entry['name']}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.surface,
                  scheme.surfaceContainerLow.withValues(alpha: 0.9),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Memory',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.9,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Pressable(
                      pressedScale: 0.99,
                      onTap: () async {
                        await RecallStore.instance.clearAll();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cleared remembered values'),
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh.withValues(
                            alpha: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const ListTile(
                          leading: Icon(Icons.history_toggle_off_outlined),
                          title: Text('Clear remembered values'),
                          subtitle: Text(
                            'Forgets saved teacher, student, and batch suggestions',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_recents.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECENT PDFS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.85,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < _recents.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        Pressable(
                          pressedScale: 0.99,
                          onTap: () => _open(_recents[i]),
                          child: Container(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHigh.withValues(
                                alpha: 0.62,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.26,
                                ),
                              ),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.picture_as_pdf_outlined,
                              ),
                              title: Text(
                                (_recents[i]['name'] as String).isEmpty
                                    ? 'Topsheet'
                                    : _recents[i]['name'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                _df.format(
                                  DateTime.parse(
                                    _recents[i]['generatedAt'] as String,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _IconAction(
                                    icon: Icons.visibility_outlined,
                                    onTap: () => _open(_recents[i]),
                                  ),
                                  _IconAction(
                                    icon: Icons.download_rounded,
                                    onTap: () => _save(_recents[i]),
                                  ),
                                  _IconAction(
                                    icon: Icons.share_outlined,
                                    onTap: () => _share(_recents[i]),
                                    primary: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _IconAction({
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Pressable(
      pressedScale: 0.92,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary
              ? scheme.primaryContainer.withValues(alpha: 0.75)
              : scheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primary
                ? scheme.primary.withValues(alpha: 0.3)
                : scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: scheme.primary,
        ),
      ),
    );
  }
}
