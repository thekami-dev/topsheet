import 'dart:isolate';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/topsheet_data.dart';

// One palette, reused everywhere in the document — matches the app's own
// seed color instead of a random blue that had nothing to do with it.
const _ink = PdfColor.fromInt(0xFF1B2A26); // primary text
const _muted = PdfColor.fromInt(0xFF5C6E68); // secondary text
const _primary = PdfColor.fromInt(0xFF3E6259); // brand teal (app seed)
const _primaryTint = PdfColor.fromInt(0xFFDCE8E3); // banner fill
const _line = PdfColor.fromInt(0xFFB9C6C1); // borders — one weight, one color
const _labelFill = PdfColor.fromInt(0xFFF1F4F3); // label-cell fill

/// Builds and serializes the PDF on a background isolate so layout +
/// zLib compression never block the UI thread (the "Generating…" spinner
/// stays animated on weak devices). The data crosses the boundary as a
/// primitive-only map via [TopsheetData.toJson].
Future<Uint8List> generateTopsheetPdf(TopsheetData d) {
  final snapshot = d.toJson();
  return Isolate.run(() async {
    final doc = await buildTopsheetPdf(TopsheetData.fromJson(snapshot));
    return doc.save();
  });
}

Future<pw.Document> buildTopsheetPdf(TopsheetData d) async {
  final doc = pw.Document();
  final df = DateFormat('dd/MM/yyyy');

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 1, color: _line)),
        padding: const pw.EdgeInsets.all(22),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _header(),
            pw.SizedBox(height: 16),
            _deptBanner(d),
            pw.SizedBox(height: 20),
            _exptTable(d, df),
            pw.SizedBox(height: 28),
            _footer(d),
          ],
        ),
      ),
    ),
  );

  return doc;
}

pw.Widget _header() => pw.Column(
      children: [
        pw.Text(
          'MAWTS Institute of Technology',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _ink),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '(Institute Code: 500123)',
          style: pw.TextStyle(fontSize: 11, color: _muted),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          '1/C-1/A, Pallabi, Mirpur-12, Dhaka-1216',
          style: pw.TextStyle(fontSize: 11, color: _muted),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2),
        pw.RichText(
          textAlign: pw.TextAlign.center,
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: 'Web: ', style: pw.TextStyle(fontSize: 11, color: _muted)),
              pw.TextSpan(
                text: 'www.mawts.org',
                style: pw.TextStyle(fontSize: 11, color: _primary, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );

pw.Widget _deptBanner(TopsheetData d) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: pw.BoxDecoration(
        color: _primaryTint,
        border: pw.Border.all(width: 1, color: _primary),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'Department of ${d.department?.longName} (${d.department?.code})',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _primary),
        textAlign: pw.TextAlign.center,
      ),
    );

pw.Widget _exptTable(TopsheetData d, DateFormat df) {
  final rows = [
    ['Subject Name', d.subject?.name ?? ''],
    ['Subject Code', '${d.subject?.code ?? ''}'],
    ['Expt. No', (d.exptNo ?? 0).toString().padLeft(2, '0')],
    ['Name of Expt', d.exptName],
    ['Date of Expt', d.dateOfExpt != null ? df.format(d.dateOfExpt!) : ''],
    ['Submission Date', d.submissionDate != null ? df.format(d.submissionDate!) : ''],
  ];
  return pw.Table(
    border: pw.TableBorder.all(width: 0.75, color: _line),
    columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1.3)},
    children: rows
        .map((r) => pw.TableRow(children: [
              pw.Container(
                color: _labelFill,
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: pw.Text(
                  r[0],
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _muted),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: pw.Text(r[1], style: pw.TextStyle(fontSize: 11, color: _ink)),
              ),
            ]))
        .toList(),
  );
}

pw.Widget _footer(TopsheetData d) => pw.Table(
      border: pw.TableBorder.all(width: 0.75, color: _line),
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
      children: [
        pw.TableRow(children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('Submitted by',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: _primary)),
                ),
                pw.SizedBox(height: 22),
                _footerLine('Name', d.studentName),
                _footerLine('Index', d.studentIndex),
                _footerLine('Board Roll', '${d.boardRoll ?? ''}'),
                _footerLine('Semester', d.semester),
                _footerLine('Batch', d.batch),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              children: [
                pw.Text('Submitted to',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: _primary)),
                pw.SizedBox(height: 60),
                pw.Text(d.teacherName,
                    style: pw.TextStyle(fontSize: 11, color: _ink, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 3),
                pw.Text(d.teacherRole, style: pw.TextStyle(fontSize: 10, color: _muted), textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 3),
                pw.Text('${d.teacherDepartment} Department',
                    style: pw.TextStyle(fontSize: 10, color: _muted), textAlign: pw.TextAlign.center),
              ],
            ),
          ),
        ]),
      ],
    );

pw.Widget _footerLine(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontSize: 10, color: _muted, fontWeight: pw.FontWeight.bold)),
            pw.TextSpan(text: value, style: pw.TextStyle(fontSize: 10, color: _ink)),
          ],
        ),
      ),
    );
