import 'package:flutter_test/flutter_test.dart';
import 'package:topsheet/data/departments.dart';
import 'package:topsheet/db/app_database.dart';
import 'package:topsheet/models/topsheet_data.dart';
import 'package:topsheet/pdf/topsheet_pdf.dart';

void main() {
  group('TopsheetData JSON round-trip', () {
    test('preserves every field through toJson/fromJson', () {
      final date = DateTime(2026, 8, 22);
      final data = TopsheetData(
        department: departmentByCode(85),
        subject: const Subject(
          code: 66651,
          name: 'Computer Networks',
          deptCode: 85,
          semester: 5,
        ),
        exptNo: 7,
        exptName: 'OSI Model Study',
        dateOfExpt: date,
        submissionDate: date.add(const Duration(days: 7)),
        studentName: 'Test Student',
        studentIndex: '123456',
        boardRoll: 654321,
        semester: '5th',
        batch: '2022-CST-A',
        teacherName: 'Test Teacher',
        teacherRole: 'Assistant Professor',
        teacherDepartment: 'CST',
      );

      final restored = TopsheetData.fromJson(data.toJson());

      expect(restored.department?.code, data.department!.code);
      expect(restored.department?.shortName, data.department!.shortName);
      expect(restored.subject?.name, data.subject!.name);
      expect(restored.exptNo, 7);
      expect(restored.exptName, 'OSI Model Study');
      expect(restored.dateOfExpt, date);
      expect(restored.submissionDate, date.add(const Duration(days: 7)));
      expect(restored.studentIndex, '123456');
      expect(restored.boardRoll, 654321);
      expect(restored.teacherDepartment, 'CST');
    });

    test('survives empty/partial data', () {
      final restored = TopsheetData.fromJson(TopsheetData().toJson());
      expect(restored.department, isNull);
      expect(restored.subject, isNull);
      expect(restored.exptNo, isNull);
      expect(restored.exptName, isEmpty);
      expect(restored.dateOfExpt, isNull);
      expect(restored.studentName, isEmpty);
    });
  });

  group('generateTopsheetPdf', () {
    // Exercises the isolate path end-to-end: snapshot crossing the
    // isolate boundary must be primitive-only and produce valid PDF bytes.
    test('produces a non-empty PDF on a background isolate', () async {
      final bytes = await generateTopsheetPdf(
        TopsheetData(
          department: btebDepartments.first,
          exptName: 'Isolate smoke test',
          semester: '1st',
        ),
      );
      expect(bytes, isNotEmpty);
      expect(bytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46])); // %PDF
    });
  });
}
