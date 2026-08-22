class SubjectSeed {
  final int code;
  final String name;
  final int deptCode;
  final int semester;

  const SubjectSeed({
    required this.code,
    required this.name,
    required this.deptCode,
    required this.semester,
  });
}

// ponytail: hand-seeded sample rows for 3 techs (CST=85, Civil=64, EEE=67)
// to prove the picker + DB pattern. Full ~2000-row set across all 41 techs
// needs transcription from BTEB syllabus PDFs — add more rows here (or a
// bulk importer) when a tech is actually needed.
const List<SubjectSeed> seedSubjects = [
  // CST (85)
  SubjectSeed(code: 85211, name: 'Structured Programming Language', deptCode: 85, semester: 2),
  SubjectSeed(code: 85212, name: 'Programming Language Sessional', deptCode: 85, semester: 2),
  SubjectSeed(code: 85311, name: 'Data Structure', deptCode: 85, semester: 3),
  SubjectSeed(code: 85321, name: 'Database Management System', deptCode: 85, semester: 3),
  SubjectSeed(code: 85411, name: 'Object Oriented Programming', deptCode: 85, semester: 4),
  SubjectSeed(code: 85421, name: 'Computer Networking', deptCode: 85, semester: 4),

  // Civil (64)
  SubjectSeed(code: 64211, name: 'Surveying-I', deptCode: 64, semester: 2),
  SubjectSeed(code: 64311, name: 'Surveying-II', deptCode: 64, semester: 3),
  SubjectSeed(code: 64321, name: 'Concrete Technology', deptCode: 64, semester: 3),
  SubjectSeed(code: 64411, name: 'Structural Analysis', deptCode: 64, semester: 4),

  // EEE / Electrical (67)
  SubjectSeed(code: 67211, name: 'Electrical Engineering Drawing', deptCode: 67, semester: 2),
  SubjectSeed(code: 67311, name: 'Electrical Machine-I', deptCode: 67, semester: 3),
  SubjectSeed(code: 67321, name: 'Electrical Circuit-II', deptCode: 67, semester: 3),
  SubjectSeed(code: 67411, name: 'Electrical Machine-II', deptCode: 67, semester: 4),
];
