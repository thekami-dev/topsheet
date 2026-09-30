import re

files = ["lib/screens/create_screen.dart", "lib/screens/library_screen.dart"]

old_block_pattern = re.compile(
    r"""PdfPreview\(
(\s*)build: \(format\) async => bytes,
\s*canChangeOrientation: false,
\s*canChangePageFormat: false,
\s*canDebug: false,
\s*useActions: false,
\s*scrollViewDecoration:.*?,
\s*pdfPreviewPageDecoration: BoxDecoration\(
\s*color: (?:Colors\.white|scheme\.surfaceContainerHighest)?,?
(?:\s*color:[^,]*,)?
\s*boxShadow: \[
\s*BoxShadow\(
\s*color:.*?,
\s*blurRadius: \d+,?
(?:\s*offset:[^,]*,)?
\s*\),
\s*\],
\s*\),
\s*allowSharing: false,
\s*allowPrinting: false,
\s*pdfFileName: ([^,]+),
\s*\)""",
    re.DOTALL,
)

def build_replacement(indent, filename_expr):
    return f"""PdfPreview(
{indent}build: (format) async => bytes,
{indent}canChangeOrientation: false,
{indent}canChangePageFormat: false,
{indent}canDebug: false,
{indent}useActions: false,
{indent}previewPageMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
{indent}maxPageWidth: 700,
{indent}scrollViewDecoration: BoxDecoration(color: scheme.surface),
{indent}pdfPreviewPageDecoration: BoxDecoration(
{indent}  color: Colors.white,
{indent}  borderRadius: BorderRadius.circular(4),
{indent}  boxShadow: [
{indent}    BoxShadow(
{indent}      color: Colors.black.withValues(alpha: 0.25),
{indent}      blurRadius: 20,
{indent}      offset: const Offset(0, 8),
{indent}    ),
{indent}  ],
{indent}),
{indent}loadingWidget: Center(
{indent}  child: CircularProgressIndicator(color: scheme.primary),
{indent}),
{indent}allowSharing: false,
{indent}allowPrinting: false,
{indent}pdfFileName: {filename_expr},
{indent})"""

total_replacements = 0
for path in files:
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    def repl(m):
        global total_replacements
        total_replacements += 1
        return build_replacement(m.group(1), m.group(2).strip())

    new_content, n = old_block_pattern.subn(repl, content)
    if n > 0:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
    print(f"{path}: {n} PdfPreview block(s) updated")

print(f"Total: {total_replacements}")
