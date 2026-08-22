import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/subject_seed.dart';

class Subject {
  final int code;
  final String name;
  final int deptCode;
  final int semester;

  const Subject({
    required this.code,
    required this.name,
    required this.deptCode,
    required this.semester,
  });

  factory Subject.fromMap(Map<String, Object?> map) => Subject(
        code: map['code'] as int,
        name: map['name'] as String,
        deptCode: map['deptCode'] as int,
        semester: map['semester'] as int,
      );
}

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  Future<Database>? _opening;

  // Subjects are seeded once at creation and never mutated, so results are
  // cached per department — the picker and draft-restore paths hit this
  // repeatedly and shouldn't pay a SQLite round-trip every time.
  final Map<int, List<Subject>> _subjectsByDept = {};

  Future<Database> get database async => _db ??= await (_opening ??= _open());

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'topsheet.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE subjects (
            code INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            deptCode INTEGER NOT NULL,
            semester INTEGER NOT NULL
          )
        ''');
        final batch = db.batch();
        for (final s in seedSubjects) {
          batch.insert('subjects', {
            'code': s.code,
            'name': s.name,
            'deptCode': s.deptCode,
            'semester': s.semester,
          });
        }
        await batch.commit(noResult: true);
      },
    );
  }

  Future<List<Subject>> subjectsForDept(int deptCode) async {
    final cached = _subjectsByDept[deptCode];
    if (cached != null) return cached;
    final db = await database;
    final rows = await db.query(
      'subjects',
      where: 'deptCode = ?',
      whereArgs: [deptCode],
      orderBy: 'semester, code',
    );
    return _subjectsByDept[deptCode] = rows.map(Subject.fromMap).toList();
  }
}
