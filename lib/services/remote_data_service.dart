import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches institute/subject data from the topsheet-data cloud endpoint,
/// with a local SharedPreferences cache so the app keeps working offline
/// once an institute+department has been picked at least once online.
class RemoteDataService {
  RemoteDataService._();
  static final RemoteDataService instance = RemoteDataService._();

  static const _baseUrl = 'https://topsheet-data.vercel.app/data'\;
  static const _timeout = Duration(seconds: 8);

  Future<List<Map<String, dynamic>>?> fetchInstitutes() async {
    final cached = await _fetchAndCache(
      url: '$_baseUrl/institutes.json',
      cacheKey: 'cache_institutes',
    );
    if (cached == null) return null;
    return (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>?> fetchSubjects(int deptCode) async {
    final cached = await _fetchAndCache(
      url: '$_baseUrl/subjects/$deptCode.json',
      cacheKey: 'cache_subjects_$deptCode',
    );
    if (cached == null) return null;
    return (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
  }

  /// Tries the network first (short timeout); on any failure, falls back
  /// to whatever was cached from a previous successful fetch. Returns null
  /// only if there's no network AND nothing cached yet.
  Future<String?> _fetchAndCache({
    required String url,
    required String cacheKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode == 200) {
        await prefs.setString(cacheKey, response.body);
        return response.body;
      }
    } catch (_) {
      // network error, timeout, DNS failure, etc. — fall through to cache
    }
    return prefs.getString(cacheKey);
  }
}
