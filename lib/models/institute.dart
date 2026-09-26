class Institute {
  final String id;
  final String name;
  final List<int> departments;

  const Institute({
    required this.id,
    required this.name,
    required this.departments,
  });

  factory Institute.fromJson(Map<String, dynamic> json) => Institute(
        id: json['id'] as String,
        name: json['name'] as String,
        departments: (json['departments'] as List).cast<int>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'departments': departments,
      };
}
