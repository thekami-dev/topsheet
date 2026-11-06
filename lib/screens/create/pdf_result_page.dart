import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:printing/printing.dart';

/// Shown right after a topsheet is generated: preview + Save / Share.
class PdfResultPage extends StatelessWidget {
  final Uint8List bytes;
  final String title;
  final String fileName;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const PdfResultPage({
    super.key,
    required this.bytes,
    required this.title,
    required this.fileName,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium,
            ),
            Text(
              'Ready to share',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
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
              pdfFileName: fileName,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: onSave,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedDownload01,
                      size: 20,
                    ),
                    label: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: onShare,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedShare01,
                      size: 20,
                    ),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
