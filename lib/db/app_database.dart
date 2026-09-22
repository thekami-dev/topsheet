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
  // cached per (department, semester) pair — the picker and draft-restore
  // paths hit this repeatedly and shouldn't pay a SQLite round-trip every
  // time. Key is "deptCode-semester".
  final Map<String, List<Subject>> _subjectsCache = {};

  Future<Database> get database async => _db ??= await (_opening ??= _open());

  Future<void> _seedSubjects(Database db) async {
    final batch = db.batch();
    for (final s in seedSubjects) {
      batch.insert(
        'subjects',
        {
          'code': s.code,
          'name': s.name,
          'deptCode': s.deptCode,
          'semester': s.semester,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'topsheet.db');
    return openDatabase(
      path,
      // Bump this whenever seedSubjects changes so installs that already
      // created the DB (and won't hit onCreate again) get the new rows via
      // onUpgrade instead of being stuck with whatever was seeded at
      // install time.
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE subjects (
            code INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            deptCode INTEGER NOT NULL,
            semester INTEGER NOT NULL
          )
        ''');
        await _seedSubjects(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Seed data may have changed between versions (new departments,
        // corrected codes, etc.) — re-seed with INSERT OR REPLACE so
        // existing installs catch up without losing the table.
        await _seedSubjects(db);
      },
    );
  }

  /// Subjects for a department, optionally narrowed to one semester
  /// (1-8). Pass null semester to get every subject for the department.
  Future<List<Subject>> subjectsForDeptAndSemester(
    int deptCode, [
    int? semester,
  ]) async {
    final cacheKey = '$deptCode-${semester ?? 'all'}';
    final cached = _subjectsCache[cacheKey];
    if (cached != null) return cached;
    final db = await database;
    final rows = await db.query(
      'subjects',
      where: semester == null ? 'deptCode = ?' : 'deptCode = ? AND semester = ?',
      whereArgs: semester == null ? [deptCode] : [deptCode, semester],
      orderBy: 'semester, code',
    );
    return _subjectsCache[cacheKey] = rows.map(Subject.fromMap).toList();
  }
}
