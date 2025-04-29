// model/Shelf.dart
class Shelf {
  final int id;
  String name;
  String? description;
  int capacityLimit;
  int currentCount;
  DateTime timeCreate;

  Shelf({
    required this.id,
    required this.name,
    this.description,
    required this.capacityLimit,
    required this.currentCount,
    required this.timeCreate,
  });

  factory Shelf.fromJson(Map<String, dynamic> json) {
    return Shelf(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      capacityLimit: (json['capacityLimit'] as num?)?.toInt() ?? 0,
      currentCount: (json['capacity'] as num?)?.toInt() ?? 0,
      timeCreate: DateTime.parse(json['timeCreate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'capacity_limit': capacityLimit,
      'current_count': currentCount,
      'timeCreate': timeCreate.toIso8601String(),
    };
  }
}
