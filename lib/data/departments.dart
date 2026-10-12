class Department {
  final String shortName;
  final String longName;
  final int code;

  const Department({
    required this.shortName,
    required this.longName,
    required this.code,
  });
}

/// Letters/digits/spaces only, lower-case — so "Civil Technology" sorts
/// before "Civil (Wood) Technology" and punctuation never decides the order.
String sortKey(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '');

int compareDepartments(Department a, Department b) =>
    sortKey(a.longName).compareTo(sortKey(b.longName));

/// In-memory department list. It is filled from the cloud
/// (`departments.json`, cached on the device) by RemoteDataService — nothing
/// is hard-coded in the app.
class DepartmentRegistry {
  DepartmentRegistry._();

  static List<Department> _sorted = const [];
  static Map<int, Department> _byCode = const {};

  static bool get isLoaded => _sorted.isNotEmpty;

  static void set(Iterable<Department> departments) {
    final list = departments.toList()..sort(compareDepartments);
    _sorted = List<Department>.unmodifiable(list);
    _byCode = {for (final d in list) d.code: d};
  }
}

/// Every department, A-Z by full name. Empty until the data has loaded.
List<Department> get btebDepartments => DepartmentRegistry._sorted;

/// O(1) code → department lookup (draft/pick restoration).
Department? departmentByCode(int code) => DepartmentRegistry._byCode[code];

/// Department codes ordered A-Z by full name; unknown codes go last.
List<int> sortedDepartmentCodes(Iterable<int> codes) {
  final list = codes.toList();
  list.sort((a, b) {
    final da = departmentByCode(a);
    final db = departmentByCode(b);
    if (da == null && db == null) return a.compareTo(b);
    if (da == null) return 1;
    if (db == null) return -1;
    return compareDepartments(da, db);
  });
  return list;
}
