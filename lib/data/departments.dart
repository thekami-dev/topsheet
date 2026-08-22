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

// BTEB Regulation 2022 technology/department codes.
// ponytail: sourced from a secondary aggregator (btebresultszone.com), not
// BTEB's own PDF directly — cross-check against bteb.gov.bd before relying
// on this for official submissions.
const List<Department> btebDepartments = [
  Department(shortName: 'ARCH', longName: 'Architecture Technology', code: 61),
  Department(shortName: 'AUTO', longName: 'Automobile Technology', code: 62),
  Department(shortName: 'CHEM', longName: 'Chemical Technology', code: 63),
  Department(shortName: 'CIVIL', longName: 'Civil Technology', code: 64),
  Department(shortName: 'CIVIL(W)', longName: 'Civil (Wood) Technology', code: 65),
  Department(shortName: 'EEE', longName: 'Electrical Technology', code: 67),
  Department(shortName: 'ETE', longName: 'Electronics Technology', code: 68),
  Department(shortName: 'FOOD', longName: 'Food Technology', code: 69),
  Department(shortName: 'MECH', longName: 'Mechanical Technology', code: 70),
  Department(shortName: 'POWER', longName: 'Power Technology', code: 71),
  Department(shortName: 'RAC', longName: 'Refrigeration & Air Conditioning Technology', code: 72),
  Department(shortName: 'SURV', longName: 'Surveying Technology', code: 78),
  Department(shortName: 'AERO', longName: 'Aerospace Technology', code: 82),
  Department(shortName: 'AVIO', longName: 'Avionics Technology', code: 83),
  Department(shortName: 'CST', longName: 'Computer Science & Technology', code: 85),
  Department(shortName: 'EMED', longName: 'Electromedical Technology', code: 86),
  Department(shortName: 'CONST', longName: 'Construction Technology', code: 88),
  Department(shortName: 'ENV', longName: 'Environmental Technology', code: 90),
  Department(shortName: 'MECHATRONICS', longName: 'Mechatronics Technology', code: 92),
  Department(shortName: 'PETRO', longName: 'Petroleum & Mining Technology', code: 93),
  Department(shortName: 'TELE', longName: 'Telecommunication Technology', code: 94),
  Department(shortName: 'PRINT', longName: 'Printing Technology', code: 95),
  Department(shortName: 'GRAPHIC', longName: 'Graphic Design Technology', code: 96),
  Department(shortName: 'FOOTWEAR', longName: 'Footwear Technology', code: 98),
  Department(shortName: 'TOURISM', longName: 'Tourism & Hospitality Technology', code: 99),
];

final Map<int, Department> _departmentsByCode = {
  for (final d in btebDepartments) d.code: d,
};

/// O(1) code → department lookup (draft/pick restoration).
Department? departmentByCode(int code) => _departmentsByCode[code];
