import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/departments.dart';
import '../models/institute.dart';

/// Fetches institutes, departments and subjects from the topsheet-data cloud
/// endpoint, with a local SharedPreferences cache so the app keeps working
/// offline once the data has been downloaded. Nothing is hard-coded.
///
/// - Cached data is returned instantly and quietly refreshed when it is
///   older than [_maxAge].
/// - Downloads share one connection, and a slow first attempt is backed up
///   by a second one after [_hedgeAfter].
/// - Only valid JSON is ever cached, so a captive-portal HTML page or a
///   half-downloaded body can never poison the cache.
class RemoteDataService {
  RemoteDataService._();
  static final RemoteDataService instance = RemoteDataService._();

  static const _baseUrl = 'https://topsheet-data.vercel.app/data';
  static const _timeout = Duration(seconds: 8);
  static const _hedgeAfter = Duration(milliseconds: 2500);
  static const _maxAge = Duration(minutes: 5);

  static const _institutesUrl = '$_baseUrl/institutes.json';
  static const _institutesKey = 'cache_institutes';
  static const _departmentsUrl = '$_baseUrl/departments.json';
  static const _departmentsKey = 'cache_departments';

  final http.Client _client = http.Client();
  final Map<String, Future<String?>> _inFlight = {};

  /// Fills the department registry. Instant when cached. With no cache it
  /// waits for the network, unless [waitForNetwork] is false (then it only
  /// starts the download and returns false).
  Future<bool> ensureDepartments({bool waitForNetwork = true}) async {
    if (DepartmentRegistry.isLoaded) return true;
    final prefs = await SharedPreferences.getInstance();
    final cached = _validCached(prefs.getString(_departmentsKey));
    if (cached != null && _applyDepartments(cached)) {
      _refreshIfStale(
        prefs,
        _departmentsUrl,
        _departmentsKey,
        onFresh: _applyDepartments,
      );
      return true;
    }
    final pending = _refresh(_departmentsUrl, _departmentsKey, _timeout).then(
      (body) => body != null && _applyDepartments(body),
    );
    if (!waitForNetwork) {
      unawaited(pending);
      return false;
    }
    return pending;
  }

  /// Valid institute rows, A-Z by name (each institute's departments are
  /// A-Z too). Null only when nothing is cached AND the network fails.
  Future<List<Map<String, dynamic>>?> fetchInstitutes() async {
    final prefs = await SharedPreferences.getInstance();

    final cached = _validCached(prefs.getString(_institutesKey));
    if (cached != null) {
      await ensureDepartments(waitForNetwork: false);
      final list = _institutesFrom(cached);
      if (list != null) {
        _refreshIfStale(prefs, _institutesUrl, _institutesKey);
        return list;
      }
    }

    // First run: nothing stored yet. Download both files at the same time.
    final institutes = _refresh(_institutesUrl, _institutesKey, _timeout);
    final departmentsOk = await ensureDepartments();
    final body = await institutes;
    if (!departmentsOk || body == null) return null;
    return _institutesFrom(body);
  }

  /// Raw decoded JSON of `subjects/<deptCode>.json`, or null when there is
  /// no network AND nothing cached.
  Future<Object?> fetchSubjectsJson(
    int deptCode, {
    Duration timeout = _timeout,
  }) async {
    final key = 'cache_subjects_$deptCode';
    final prefs = await SharedPreferences.getInstance();
    final cached = _validCached(prefs.getString(key));
    final body =
        await _refresh('$_baseUrl/subjects/$deptCode.json', key, timeout) ??
        cached;
    return body == null ? null : _decode(body);
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

  void _refreshIfStale(
    SharedPreferences prefs,
    String url,
    String key, {
    void Function(String body)? onFresh,
  }) {
    final savedAt = prefs.getInt('${key}_at') ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - savedAt;
    if (age <= _maxAge.inMilliseconds) return;
    unawaited(
      _refresh(url, key, _timeout).then((body) {
        if (body != null) onFresh?.call(body);
      }),
    );
  }

  /// One shared download per key; callers asking while it runs get the same
  /// future.
  Future<String?> _refresh(String url, String cacheKey, Duration timeout) {
    return _inFlight[cacheKey] ??= _downloadWithBackup(
      url,
      cacheKey,
      timeout,
    ).whenComplete(() => _inFlight.remove(cacheKey));
  }

  /// First attempt; if it is slow (or fails quickly) a second one starts and
  /// whichever succeeds first wins.
  Future<String?> _downloadWithBackup(
    String url,
    String cacheKey,
    Duration timeout,
  ) {
    final result = Completer<String?>();
    var started = 1;
    var failures = 0;

    void attempt() {
      _download(url, cacheKey, timeout).then((body) {
        if (result.isCompleted) return;
        if (body != null) {
          result.complete(body);
          return;
        }
        failures++;
        if (failures >= 2) {
          result.complete(null);
        } else if (started < 2) {
          started = 2;
          attempt();
        }
      });
    }

    attempt();
    Timer(_hedgeAfter, () {
      if (!result.isCompleted && started < 2) {
        started = 2;
        attempt();
      }
    });
    return result.future;
  }

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
      await prefs.setInt(
        '${cacheKey}_at',
        DateTime.now().millisecondsSinceEpoch,
      );
      return body;
    } catch (_) {
      // network error, timeout, DNS failure, bad body
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
