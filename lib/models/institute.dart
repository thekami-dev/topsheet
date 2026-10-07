class Institute {
  final String id;
  final String name;
  final String? code;
  final String? address;
  final String? website;
  final List<int> departments;

  const Institute({
    required this.id,
    required this.name,
    this.code,
    this.address,
    this.website,
    required this.departments,
  });

  factory Institute.fromJson(Map<String, dynamic> json) => Institute(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String?,
        address: json['address'] as String?,
        website: json['website'] as String?,
        departments: (json['departments'] as List).cast<int>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'address': address,
        'website': website,
        'departments': departments,
      };
}
