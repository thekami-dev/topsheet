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
  // CST (85) — full Probidhan-2022 course structure, semesters 1-7,
  // transcribed from BTEB's official syllabus PDF. Semester 8
  // (Industrial Attachment / Project Presentation) is omitted: the PDF's
  // code column is merged/ambiguous there, so codes weren't reliably
  // readable — fill in once confirmed against the source PDF directly.

  // Semester 1
  SubjectSeed(code: 21011, name: 'Engineering Drawing', deptCode: 85, semester: 1),
  SubjectSeed(code: 25711, name: 'Bangla-I', deptCode: 85, semester: 1),
  SubjectSeed(code: 25712, name: 'English-I', deptCode: 85, semester: 1),
  SubjectSeed(code: 25911, name: 'Mathematics-I', deptCode: 85, semester: 1),
  SubjectSeed(code: 25912, name: 'Physics-I', deptCode: 85, semester: 1),
  SubjectSeed(code: 28511, name: 'Computer Office Application', deptCode: 85, semester: 1),
  SubjectSeed(code: 26711, name: 'Basic Electricity', deptCode: 85, semester: 1),

  // Semester 2
  SubjectSeed(code: 25721, name: 'Bangla-II', deptCode: 85, semester: 2),
  SubjectSeed(code: 25722, name: 'English-II', deptCode: 85, semester: 2),
  SubjectSeed(code: 25812, name: 'Physical Education & Life Skills Development', deptCode: 85, semester: 2),
  SubjectSeed(code: 25913, name: 'Chemistry', deptCode: 85, semester: 2),
  SubjectSeed(code: 25921, name: 'Mathematics-II', deptCode: 85, semester: 2),
  SubjectSeed(code: 28521, name: 'Python Programming', deptCode: 85, semester: 2),
  SubjectSeed(code: 28522, name: 'Computer Graphics Design-I', deptCode: 85, semester: 2),
  SubjectSeed(code: 26811, name: 'Basic Electronics', deptCode: 85, semester: 2),

  // Semester 3
  SubjectSeed(code: 25811, name: 'Social Science', deptCode: 85, semester: 3),
  SubjectSeed(code: 25922, name: 'Physics-II', deptCode: 85, semester: 3),
  SubjectSeed(code: 25931, name: 'Mathematics-III', deptCode: 85, semester: 3),
  SubjectSeed(code: 28531, name: 'Application Development Using Python', deptCode: 85, semester: 3),
  SubjectSeed(code: 28532, name: 'Computer Graphics Design-II', deptCode: 85, semester: 3),
  SubjectSeed(code: 28533, name: 'IT Support Services', deptCode: 85, semester: 3),
  SubjectSeed(code: 26831, name: 'Digital Electronics-I', deptCode: 85, semester: 3),

  // Semester 4
  SubjectSeed(code: 25831, name: 'Business Communication', deptCode: 85, semester: 4),
  SubjectSeed(code: 28541, name: 'Java Programming', deptCode: 85, semester: 4),
  SubjectSeed(code: 28542, name: 'Data Structure & Algorithm', deptCode: 85, semester: 4),
  SubjectSeed(code: 28543, name: 'Computer Peripherals & Interfacing', deptCode: 85, semester: 4),
  SubjectSeed(code: 28544, name: 'Web Design & Development-I', deptCode: 85, semester: 4),
  SubjectSeed(code: 26841, name: 'Digital Electronics-II', deptCode: 85, semester: 4),
  SubjectSeed(code: 29041, name: 'Environmental Studies', deptCode: 85, semester: 4),

  // Semester 5
  SubjectSeed(code: 25841, name: 'Accounting', deptCode: 85, semester: 5),
  SubjectSeed(code: 28551, name: 'Application Development Using Java', deptCode: 85, semester: 5),
  SubjectSeed(code: 28552, name: 'Web Design & Development-II', deptCode: 85, semester: 5),
  SubjectSeed(code: 28553, name: 'Computer Architecture & Microprocessor', deptCode: 85, semester: 5),
  SubjectSeed(code: 28554, name: 'Data Communication', deptCode: 85, semester: 5),
  SubjectSeed(code: 28555, name: 'Operating System', deptCode: 85, semester: 5),
  SubjectSeed(code: 28556, name: 'Project Work-I', deptCode: 85, semester: 5),

  // Semester 6
  SubjectSeed(code: 25851, name: 'Principles of Marketing', deptCode: 85, semester: 6),
  SubjectSeed(code: 25852, name: 'Industrial Management', deptCode: 85, semester: 6),
  SubjectSeed(code: 28561, name: 'Database Management System', deptCode: 85, semester: 6),
  SubjectSeed(code: 28562, name: 'Computer Networking', deptCode: 85, semester: 6),
  SubjectSeed(code: 28563, name: 'Sensor & IoT System', deptCode: 85, semester: 6),
  SubjectSeed(code: 28564, name: 'Microcontroller Based System Design & Development', deptCode: 85, semester: 6),
  SubjectSeed(code: 28565, name: 'Surveillance Security System', deptCode: 85, semester: 6),
  SubjectSeed(code: 28566, name: 'Web Development Project', deptCode: 85, semester: 6),

  // Semester 7
  SubjectSeed(code: 25853, name: 'Innovation & Entrepreneurship', deptCode: 85, semester: 7),
  SubjectSeed(code: 28571, name: 'Digital Marketing Technique', deptCode: 85, semester: 7),
  SubjectSeed(code: 28572, name: 'Network Administration & Services', deptCode: 85, semester: 7),
  SubjectSeed(code: 28573, name: 'Cyber Security & Ethics', deptCode: 85, semester: 7),
  SubjectSeed(code: 28574, name: 'Apps Development Project', deptCode: 85, semester: 7),
  SubjectSeed(code: 28575, name: 'Multimedia & Animation', deptCode: 85, semester: 7),
  SubjectSeed(code: 28576, name: 'Project Work-II', deptCode: 85, semester: 7),

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
