import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/subject_seed.dart';
import '../services/remote_data_service.dart';

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

  // Results are cached per (department, semester) pair — the picker and
  // draft-restore paths hit this repeatedly. Key is "deptCode-semester".
  // Cleared for a department whenever its subjects are synced.
  final Map<String, List<Subject>> _subjectsCache = {};

  // Departments already refreshed from the cloud this session.
  final Set<int> _synced = {};
  final Map<int, DateTime> _lastAttempt = {};
  final Map<int, Future<bool>> _syncing = {};

  Future<Database> get database async => _db ??= await (_opening ??= _open());

  Future<void> _createSubjectsTable(Database db) => db.execute('''
    CREATE TABLE subjects (
      code INTEGER NOT NULL,
      name TEXT NOT NULL,
      deptCode INTEGER NOT NULL,
      semester INTEGER NOT NULL,
      PRIMARY KEY (deptCode, code)
    )
  ''');

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
      // v3: primary key is now (deptCode, code). Many subject codes (e.g.
      // Bangla-I) are shared by every department, so the old key (code
      // alone) let one department's row overwrite another's.
      version: 3,
      onCreate: (db, version) async {
        await _createSubjectsTable(db);
        await _seedSubjects(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // The table only holds seed + cloud data, so rebuilding it is safe.
          await db.execute('DROP TABLE IF EXISTS subjects');
          await _createSubjectsTable(db);
        }
        await _seedSubjects(db);
      },
    );
  }

  /// Subjects for a department, optionally narrowed to one semester
  /// (1-8). Pass null semester to get every subject for the department.
  ///
  /// If nothing is stored locally for the department yet, the cloud copy is
  /// downloaded once and stored. If something is stored, it is returned
  /// immediately and refreshed in the background.
  Future<List<Subject>> subjectsForDeptAndSemester(
    int deptCode, [
    int? semester,
  ]) async {
    var list = await _query(deptCode, semester);
    if (_synced.contains(deptCode)) return list;
    if (list.isEmpty) {
      if (await syncSubjects(deptCode)) {
        list = await _query(deptCode, semester);
      }
    } else {
      unawaited(syncSubjects(deptCode));
    }
    return list;
  }

  /// Downloads `subjects/<deptCode>.json` and upserts it into the local DB.
  /// Returns true if rows were stored. Seed rows are never deleted.
  Future<bool> syncSubjects(
    int deptCode, {
    bool force = false,
    Duration timeout = const Duration(seconds: 6),
  }) {
    final running = _syncing[deptCode];
    if (running != null) return running;
    if (!force) {
      if (_synced.contains(deptCode)) return Future.value(false);
      final last = _lastAttempt[deptCode];
      if (last != null &&
          DateTime.now().difference(last) < const Duration(seconds: 45)) {
        // Just tried and failed (offline?) — don't make every screen wait.
        return Future.value(false);
      }
    }
    _lastAttempt[deptCode] = DateTime.now();
    final f = _doSync(deptCode, timeout).whenComplete(
      () => _syncing.remove(deptCode),
    );
    _syncing[deptCode] = f;
    return f;
  }

  Future<bool> _doSync(int deptCode, Duration timeout) async {
    try {
      final decoded = await RemoteDataService.instance.fetchSubjectsJson(
        deptCode,
        timeout: timeout,
      );
      if (decoded == null) return false;
      final rows = _parseSubjects(decoded, deptCode);
      if (rows.isEmpty) return false;
      final db = await database;
      final batch = db.batch();
      for (final s in rows) {
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
      _synced.add(deptCode);
      _subjectsCache.removeWhere((key, _) => key.startsWith('$deptCode-'));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Subject>> _query(int deptCode, int? semester) async {
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
    final list = rows.map(Subject.fromMap).toList();
    if (list.isNotEmpty) _subjectsCache[cacheKey] = list;
    return list;
  }
}

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final m = RegExp(r'\d+').firstMatch(v);
    return m == null ? null : int.tryParse(m.group(0)!);
  }
  return null;
}

/// Accepts a list of rows, `{"subjects": [...]}`, or `{"1": [...], "2": [...]}`
/// (semester → rows). Rows that can't be read are skipped.
List<Subject> _parseSubjects(Object? decoded, int deptCode) {
  final out = <Subject>[];

  void addRow(Object? row, [int? fallbackSemester]) {
    if (row is! Map) return;
    final code = _asInt(row['code'] ?? row['subjectCode']);
    final name = row['name'] ?? row['subjectName'] ?? row['title'];
    final semester = _asInt(row['semester'] ?? row['sem']) ?? fallbackSemester;
    if (code == null || semester == null) return;
    if (name is! String || name.trim().isEmpty) return;
    if (semester < 1 || semester > 8) return;
    out.add(
      Subject(
        code: code,
        name: name.trim(),
        deptCode: deptCode,
        semester: semester,
      ),
    );
  }

  Object? root = decoded;
  if (root is Map && root['subjects'] is List) root = root['subjects'];
  if (root is List) {
    for (final r in root) {
      addRow(r);
    }
  } else if (root is Map) {
    root.forEach((key, value) {
      final sem = _asInt(key);
      if (value is List) {
        for (final r in value) {
          addRow(r, sem);
        }
      }
    });
  }
  return out;
}
