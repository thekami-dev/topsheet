import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Remembers what the user typed last time, per field, so repeat
/// topsheets (same teacher/department/batch, different experiment)
/// don't need retyping. Backed by SharedPreferences — a handful of
/// short string lists, not worth a DB table.
class RecallStore {
  RecallStore._();
  static final RecallStore instance = RecallStore._();

  static const _maxSuggestions = 8;

  Future<List<String>> suggestionsFor(String field) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('recall_$field');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> remember(String field, String value) {
    if (value.trim().isEmpty) return Future.value();
    return rememberAll({field: value});
  }

  /// Records every field in a single SharedPreferences pass — one
  /// getInstance and one read-modify-write cycle per field, no repeated
  /// instance fetches between entries.
  Future<void> rememberAll(Map<String, String> fieldValues) async {
    if (fieldValues.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    for (final entry in fieldValues.entries) {
      final value = entry.value.trim();
      if (value.isEmpty) continue;
      final key = 'recall_${entry.key}';
      final raw = prefs.getString(key);
      final existing =
          raw == null ? <String>[] : (jsonDecode(raw) as List).cast<String>();
      existing.remove(value);
      existing.insert(0, value);
      if (existing.length > _maxSuggestions) existing.removeLast();
      await prefs.setString(key, jsonEncode(existing));
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
          (k) => k.startsWith('recall_') || k.startsWith('lastPick_') || k == 'studentProfiles',
        );
    await Future.wait(keys.map(prefs.remove));
  }

  // Last-used dept/subject/semester picks, so the picker screens preselect
  // instead of forcing a re-tap every topsheet.
  Future<void> rememberLastPicks({required int deptCode, required int subjectCode, required String semester}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastPick_dept', deptCode);
    await prefs.setInt('lastPick_subject', subjectCode);
    await prefs.setString('lastPick_semester', semester);
  }

  Future<(int, int, String)?> lastPicks() async {
    final prefs = await SharedPreferences.getInstance();
    final dept = prefs.getInt('lastPick_dept');
    final subject = prefs.getInt('lastPick_subject');
    final semester = prefs.getString('lastPick_semester');
    if (dept == null || subject == null || semester == null) return null;
    return (dept, subject, semester);
  }

  Future<bool> hintSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hintSeen') ?? false;
  }

  Future<void> markHintSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hintSeen', true);
  }

  // In-progress form, saved whenever the app is backgrounded so a user who
  // gets interrupted mid-fill doesn't lose everything on next open.
  Future<void> saveDraft(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft', jsonEncode(json));
  }

  Future<Map<String, dynamic>?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('draft');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft');
  }

  // Per-student profile, keyed by name, so picking a remembered name
  // autofills their index/roll/batch instead of just the name field.
  Future<void> saveStudentProfile(String name, Map<String, String> fields) async {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('studentProfiles');
    final all = raw == null ? <String, dynamic>{} : jsonDecode(raw) as Map<String, dynamic>;
    all[key] = fields;
    await prefs.setString('studentProfiles', jsonEncode(all));
  }

  Future<Map<String, String>?> studentProfile(String name) async {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('studentProfiles');
    if (raw == null) return null;
    final all = jsonDecode(raw) as Map<String, dynamic>;
    final entry = all[key] as Map<String, dynamic>?;
    return entry?.cast<String, String>();
  }

  // Practically unlimited for a personal-use app — this is a library now,
  // not a "last few" cache. Cap exists only to stop unbounded growth.
  static const _maxRecentPdfs = 500;

  /// Recent generated PDFs, newest first:
  /// `{path, name, generatedAt, formData}` — formData is the full
  /// TopsheetData snapshot (as JSON) so a saved topsheet can be reopened
  /// for editing, not just viewed/shared.
  Future<List<Map<String, dynamic>>> recentPdfs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('recentPdfs');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  /// Records a newly-saved PDF and returns the paths of any entries dropped
  /// off the end of the cap, so the caller can delete those files too.
  Future<List<String>> addRecentPdf({
    required String path,
    required String name,
    Map<String, dynamic>? formData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await recentPdfs();
    list.insert(0, {
      'path': path,
      'name': name,
      'generatedAt': DateTime.now().toIso8601String(),
      'formData': formData,
    });
    final dropped = <String>[];
    while (list.length > _maxRecentPdfs) {
      dropped.add(list.removeLast()['path'] as String);
    }
    await prefs.setString('recentPdfs', jsonEncode(list));
    return dropped;
  }

  /// Onboarding: has the user completed the first-run setup flow?
  Future<bool> onboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboardingComplete') ?? false;
  }

  /// Saves the user's profile from onboarding (or a later edit in
  /// Settings). All fields are sticky defaults — used to prefill new
  /// Topsheets, but always editable per-Topsheet afterward.
  Future<void> saveProfile({
    required String name,
    required String studentIndex,
    required String instituteId,
    required String instituteName,
    required int deptCode,
    required String semester,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_index', studentIndex);
    await prefs.setString('profile_instituteId', instituteId);
    await prefs.setString('profile_instituteName', instituteName);
    await prefs.setInt('profile_deptCode', deptCode);
    await prefs.setString('profile_semester', semester);
    await prefs.setBool('onboardingComplete', true);
  }

  /// Returns the saved profile, or null if onboarding hasn't been
  /// completed yet.
  Future<Map<String, dynamic>?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('onboardingComplete') ?? false)) return null;
    return {
      'name': prefs.getString('profile_name') ?? '',
      'studentIndex': prefs.getString('profile_index') ?? '',
      'instituteId': prefs.getString('profile_instituteId') ?? '',
      'instituteName': prefs.getString('profile_instituteName') ?? '',
      'deptCode': prefs.getInt('profile_deptCode'),
      'semester': prefs.getString('profile_semester') ?? '',
    };
  }

  /// Theme preference: 'system' | 'light' | 'dark'
  Future<String> themeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('themeMode') ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode);
  }

  Future<void> removeRecentPdf(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await recentPdfs();
    list.removeWhere((e) => e['path'] == path);
    await prefs.setString('recentPdfs', jsonEncode(list));
  }
}
