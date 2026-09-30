# --- create_screen.dart: lines 1246-1265 (PdfPreview(...) block) ---
path1 = "lib/screens/create_screen.dart"
with open(path1, "r", encoding="utf-8") as f:
    lines1 = f.readlines()

new_block1 = '''            child: PdfPreview(
              build: (format) async => bytes,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              useActions: false,
              previewPageMargin: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
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
              loadingWidget: Center(
                child: CircularProgressIndicator(color: scheme.primary),
              ),
              allowSharing: false,
              allowPrinting: false,
              pdfFileName: fileName,
            ),
'''

start1, end1 = 1246, 1266  # 1-indexed inclusive: "child: PdfPreview(" through the closing "),"
lines1[start1-1:end1] = [new_block1]

with open(path1, "w", encoding="utf-8") as f:
    f.writelines(lines1)
print(f"✅ create_screen.dart: PdfPreview block replaced (lines {start1}-{end1}).")

# --- library_screen.dart: lines 583-602 ---
path2 = "lib/screens/library_screen.dart"
with open(path2, "r", encoding="utf-8") as f:
    lines2 = f.readlines()

new_block2 = '''      body: PdfPreview(
        build: (format) async => bytes,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        useActions: false,
        previewPageMargin: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
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
        loadingWidget: Center(
          child: CircularProgressIndicator(color: scheme.primary),
        ),
        allowSharing: false,
        allowPrinting: false,
        pdfFileName: '$name.pdf',
      ),
'''

start2, end2 = 583, 602
lines2[start2-1:end2] = [new_block2]

with open(path2, "w", encoding="utf-8") as f:
    f.writelines(lines2)
print(f"✅ library_screen.dart: PdfPreview block replaced (lines {start2}-{end2}).")
