import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/institute.dart';

/// Fetches institute/subject data from the topsheet-data cloud endpoint,
/// with a local SharedPreferences cache so the app keeps working offline.
///
/// - Institutes: cache first (instant), refreshed in the background when
///   older than [_maxAge].
/// - Subjects: network first, cache as fallback (see AppDatabase.syncSubjects).
/// - Only valid JSON is ever cached, so a captive-portal HTML page or a
///   half-downloaded body can never poison the cache.
class RemoteDataService {
  RemoteDataService._();
  static final RemoteDataService instance = RemoteDataService._();

  static const _baseUrl = 'https://topsheet-data.vercel.app/data';
  static const _timeout = Duration(seconds: 8);
  static const _maxAge = Duration(hours: 6);

  final Map<String, Future<String?>> _inFlight = {};

  /// Valid institute rows, or null when there is no network AND no cache.
  Future<List<Map<String, dynamic>>?> fetchInstitutes() async {
    final body = await _load(
      url: '$_baseUrl/institutes.json',
      cacheKey: 'cache_institutes',
      cacheFirst: true,
    );
    if (body == null) return null;
    final decoded = _decode(body);
    if (decoded is! List) return null;
    final out = <Map<String, dynamic>>[];
    for (final row in decoded) {
      if (row is! Map) continue;
      final json = Map<String, dynamic>.from(row);
      try {
        // Forces the lazy casts inside Institute.fromJson to run now, so a
        // malformed row is dropped here instead of crashing a screen later.
        Institute.fromJson(json).departments.toList();
        out.add(json);
      } catch (_) {
        // skip malformed row
      }
    }
    return out;
  }

  /// Raw decoded JSON of `subjects/<deptCode>.json`, or null when there is
  /// no network AND nothing cached.
  Future<Object?> fetchSubjectsJson(
    int deptCode, {
    Duration timeout = _timeout,
  }) async {
    final body = await _load(
      url: '$_baseUrl/subjects/$deptCode.json',
      cacheKey: 'cache_subjects_$deptCode',
      cacheFirst: false,
      timeout: timeout,
    );
    return body == null ? null : _decode(body);
  }

  Future<String?> _load({
    required String url,
    required String cacheKey,
    required bool cacheFirst,
    Duration timeout = _timeout,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = _validCached(prefs.getString(cacheKey));
    if (cacheFirst && cached != null) {
      final savedAt = prefs.getInt('${cacheKey}_at') ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - savedAt;
      if (age > _maxAge.inMilliseconds) {
        unawaited(_refresh(url, cacheKey, timeout));
      }
      return cached;
    }
    return await _refresh(url, cacheKey, timeout) ?? cached;
  }

  Future<String?> _refresh(String url, String cacheKey, Duration timeout) {
    return _inFlight[cacheKey] ??= _download(
      url,
      cacheKey,
      timeout,
    ).whenComplete(() => _inFlight.remove(cacheKey));
  }

  Future<String?> _download(
    String url,
    String cacheKey,
    Duration timeout,
  ) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(timeout);
      if (response.statusCode != 200) return null;
      final body = utf8.decode(response.bodyBytes);
      final decoded = _decode(body);
      if (decoded is! List && decoded is! Map) return null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, body);
      await prefs.setInt(
        '${cacheKey}_at',
        DateTime.now().millisecondsSinceEpoch,
      );
      return body;
    } catch (_) {
      // network error, timeout, DNS failure, bad body — caller falls back
      // to whatever is cached.
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
