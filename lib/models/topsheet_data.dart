import '../data/departments.dart';
import '../db/app_database.dart';

class TopsheetData {
  Department? department;
  Subject? subject;
  int? exptNo;
  String exptName;
  DateTime? dateOfExpt;
  DateTime? submissionDate;
  String studentName;
  String studentIndex;
  int? boardRoll;
  String semester;
  String batch;
  String teacherName;
  String teacherRole;
  String teacherDepartment;

  TopsheetData({
    this.department,
    this.subject,
    this.exptNo,
    this.exptName = '',
    this.dateOfExpt,
    this.submissionDate,
    this.studentName = '',
    this.studentIndex = '',
    this.boardRoll,
    this.semester = '',
    this.batch = '',
    this.teacherName = '',
    this.teacherRole = '',
    this.teacherDepartment = '',
  });

  /// Primitive-only snapshot, safe to send across isolate boundaries
  /// (Department/Subject instances themselves are not sendable).
  Map<String, dynamic> toJson() => {
        'department': department == null
            ? null
            : {
                'shortName': department!.shortName,
                'longName': department!.longName,
                'code': department!.code,
              },
        'subject': subject == null
            ? null
            : {
                'code': subject!.code,
                'name': subject!.name,
                'deptCode': subject!.deptCode,
                'semester': subject!.semester,
              },
        'exptNo': exptNo,
        'exptName': exptName,
        'dateOfExpt': dateOfExpt?.toIso8601String(),
        'submissionDate': submissionDate?.toIso8601String(),
        'studentName': studentName,
        'studentIndex': studentIndex,
        'boardRoll': boardRoll,
        'semester': semester,
        'batch': batch,
        'teacherName': teacherName,
        'teacherRole': teacherRole,
        'teacherDepartment': teacherDepartment,
      };

  factory TopsheetData.fromJson(Map<String, dynamic> json) {
    final deptJson = json['department'] as Map<String, dynamic>?;
    final subjJson = json['subject'] as Map<String, dynamic>?;
    return TopsheetData(
      department: deptJson == null
          ? null
          : Department(
              shortName: deptJson['shortName'] as String,
              longName: deptJson['longName'] as String,
              code: deptJson['code'] as int,
            ),
      subject: subjJson == null
          ? null
          : Subject(
              code: subjJson['code'] as int,
              name: subjJson['name'] as String,
              deptCode: subjJson['deptCode'] as int,
              semester: subjJson['semester'] as int,
            ),
      exptNo: json['exptNo'] as int?,
      exptName: json['exptName'] as String? ?? '',
      dateOfExpt: DateTime.tryParse(json['dateOfExpt'] as String? ?? ''),
      submissionDate: DateTime.tryParse(json['submissionDate'] as String? ?? ''),
      studentName: json['studentName'] as String? ?? '',
      studentIndex: json['studentIndex'] as String? ?? '',
      boardRoll: json['boardRoll'] as int?,
      semester: json['semester'] as String? ?? '',
      batch: json['batch'] as String? ?? '',
      teacherName: json['teacherName'] as String? ?? '',
      teacherRole: json['teacherRole'] as String? ?? '',
      teacherDepartment: json['teacherDepartment'] as String? ?? '',
    );
  }

  bool get isComplete =>
      department != null &&
      subject != null &&
      exptNo != null &&
      exptName.isNotEmpty &&
      dateOfExpt != null &&
      submissionDate != null &&
      studentName.isNotEmpty &&
      studentIndex.isNotEmpty &&
      boardRoll != null &&
      semester.isNotEmpty &&
      batch.isNotEmpty &&
      teacherName.isNotEmpty &&
      teacherRole.isNotEmpty &&
      teacherDepartment.isNotEmpty;
}

const List<String> semesters = [
  '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th',
];
