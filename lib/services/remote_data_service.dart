import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/departments.dart';
import '../models/institute.dart';

/// Institutes, departments and subjects come from the topsheet-data cloud
/// endpoint. Nothing is hard-coded in the app.
///
/// - Online: the live data is shown (and saved on the phone).
/// - Offline: the saved copy is shown.
/// - A live download starts when the app opens and is repeated whenever a
///   screen asks and the last one is older than [_refreshEvery]. It runs in
///   the background, so no screen has to wait for it once a saved copy exists.
class RemoteDataService {
  RemoteDataService._();
  static final RemoteDataService instance = RemoteDataService._();

  static const _host = 'topsheet-data.vercel.app';
  static const _baseUrl = 'https://$_host/data'\;
  static const _timeout = Duration(seconds: 10);
  static const _refreshEvery = Duration(seconds: 30);

  static const _institutesUrl = '$_baseUrl/institutes.json';
  static const _institutesKey = 'cache_institutes';
  static const _departmentsUrl = '$_baseUrl/departments.json';
  static const _departmentsKey = 'cache_departments';

  final http.Client _client = http.Client();
  Future<void>? _refreshing;
  DateTime? _lastLive;

  /// Latest institutes known to the app: live data when online, otherwise
  /// the saved copy. Null until the first copy is available. Screens can
  /// listen to it and update themselves when live data arrives.
  final ValueNotifier<List<Map<String, dynamic>>?> institutes =
      ValueNotifier<List<Map<String, dynamic>>?>(null);

  /// Loads the saved copies into memory. Instant, no network.
  Future<void> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final depts = _validCached(prefs.getString(_departmentsKey));
    if (depts != null) _applyDepartments(depts);
    final inst = _validCached(prefs.getString(_institutesKey));
    if (inst != null) _applyInstitutes(inst);
  }

  /// Downloads departments and institutes and updates the in-memory copies.
  /// Concurrent calls share one download. Never throws.
  Future<void> refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<void> _doRefresh() async {
    final results = await Future.wait([
      _download(_departmentsUrl, _departmentsKey, _timeout),
      _download(_institutesUrl, _institutesKey, _timeout),
    ]);
    final depts = results[0];
    final inst = results[1];
    // Departments first: institutes use them to order their own lists.
    if (depts != null) _applyDepartments(depts);
    if (inst != null) _applyInstitutes(inst);
    if (depts != null || inst != null) _lastLive = DateTime.now();
  }

  void _refreshIfDue() {
    final last = _lastLive;
    if (last != null && DateTime.now().difference(last) < _refreshEvery) {
      return;
    }
    unawaited(refresh());
  }

  /// Makes sure the department list is in memory. Instant when a saved copy
  /// exists. With nothing saved it waits for the download, unless
  /// [waitForNetwork] is false (then it only starts it and returns false).
  Future<bool> ensureDepartments({bool waitForNetwork = true}) async {
    if (DepartmentRegistry.isLoaded) {
      _refreshIfDue();
      return true;
    }
    await loadCache();
    if (DepartmentRegistry.isLoaded) {
      _refreshIfDue();
      return true;
    }
    if (!waitForNetwork) {
      unawaited(refresh());
      return false;
    }
    await refresh();
    return DepartmentRegistry.isLoaded;
  }

  /// Institutes (A-Z, each with its departments A-Z). Returns the best copy
  /// available right now: saved copy instantly, or the live download on the
  /// very first launch. Null only when there is nothing saved AND the
  /// download failed.
  Future<List<Map<String, dynamic>>?> fetchInstitutes() async {
    if (institutes.value == null) await loadCache();
    final current = institutes.value;
    if (current != null) {
      _refreshIfDue();
      return current;
    }
    // Nothing saved yet (first launch): wait for the live download.
    await refresh();
    if (!DepartmentRegistry.isLoaded) return null;
    return institutes.value;
  }

  /// Raw decoded JSON of `subjects/<deptCode>.json`: live when online,
  /// otherwise the saved copy, otherwise null.
  Future<Object?> fetchSubjectsJson(
    int deptCode, {
    Duration timeout = _timeout,
  }) async {
    final key = 'cache_subjects_$deptCode';
    final live = await _download(
      '$_baseUrl/subjects/$deptCode.json',
      key,
      timeout,
    );
    if (live != null) return _decode(live);
    final prefs = await SharedPreferences.getInstance();
    final saved = _validCached(prefs.getString(key));
    return saved == null ? null : _decode(saved);
  }

  bool _applyDepartments(String body) {
    final decoded = _decode(body);
    if (decoded is! List) return false;
    final list = <Department>[];
    for (final row in decoded) {
      if (row is! Map) continue;
      final code = row['code'];
      final shortName = row['shortName'];
      final longName = row['longName'];
      if (code is int && shortName is String && longName is String) {
        list.add(
          Department(shortName: shortName, longName: longName, code: code),
        );
      }
    }
    if (list.isEmpty) return false;
    DepartmentRegistry.set(list);
    return true;
  }

  void _applyInstitutes(String body) {
    final list = _institutesFrom(body);
    if (list != null) institutes.value = list;
  }

  /// Parses, validates and sorts an institutes JSON body.
  List<Map<String, dynamic>>? _institutesFrom(String body) {
    final decoded = _decode(body);
    if (decoded is! List) return null;
    final out = <Map<String, dynamic>>[];
    for (final row in decoded) {
      if (row is! Map) continue;
      final json = Map<String, dynamic>.from(row);
      try {
        // Forces the lazy casts inside Institute.fromJson to run now, so a
        // malformed row is dropped here instead of crashing a screen later.
        final inst = Institute.fromJson(json);
        json['departments'] = sortedDepartmentCodes(inst.departments);
        out.add(json);
      } catch (_) {
        // skip malformed row
      }
    }
    out.sort(
      (a, b) =>
          sortKey(a['name'] as String).compareTo(sortKey(b['name'] as String)),
    );
    return out;
  }

  /// One request. On success the body is saved on the phone and returned.
  /// Any failure (no network, timeout, bad status, bad JSON) returns null.
  Future<String?> _download(
    String url,
    String cacheKey,
    Duration timeout,
  ) async {
    try {
      final response = await _client.get(Uri.parse(url)).timeout(timeout);
      if (response.statusCode != 200) return null;
      final body = utf8.decode(response.bodyBytes);
      final decoded = _decode(body);
      if (decoded is! List && decoded is! Map) return null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, body);
      return body;
    } catch (_) {
      return null;
    }
  }

  String? _validCached(String? raw) {
    if (raw == null) return null;
    final decoded = _decode(raw);
    return (decoded is List || decoded is Map) ? raw : null;
  }

  Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
