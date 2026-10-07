path = "lib/data/recall_store.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

old = """  Future<void> saveProfile({
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
  }"""

new = """  Future<void> saveProfile({
    required String name,
    required String studentIndex,
    required String instituteId,
    required String instituteName,
    String? instituteCode,
    String? instituteAddress,
    String? instituteWebsite,
    required int deptCode,
    required String semester,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_index', studentIndex);
    await prefs.setString('profile_instituteId', instituteId);
    await prefs.setString('profile_instituteName', instituteName);
    await prefs.setString('profile_instituteCode', instituteCode ?? '');
    await prefs.setString('profile_instituteAddress', instituteAddress ?? '');
    await prefs.setString('profile_instituteWebsite', instituteWebsite ?? '');
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
      'instituteCode': prefs.getString('profile_instituteCode') ?? '',
      'instituteAddress': prefs.getString('profile_instituteAddress') ?? '',
      'instituteWebsite': prefs.getString('profile_instituteWebsite') ?? '',
      'deptCode': prefs.getInt('profile_deptCode'),
      'semester': prefs.getString('profile_semester') ?? '',
    };
  }"""

assert content.count(old) == 1, f"matched {content.count(old)} times"
content = content.replace(old, new)
with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("✅ recall_store.dart updated.")
