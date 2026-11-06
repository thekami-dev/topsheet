import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:printing/printing.dart';

class PdfPreviewPage extends StatelessWidget {
  final Uint8List bytes;
  final String name;

  const PdfPreviewPage({super.key, required this.bytes, required this.name});

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
