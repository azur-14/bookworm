class Room {
  String id;
  String name;
  String floor;
  int capacity;
  int fee; // fee: phí một giờ

  Room({
    required this.id,
    required this.name,
    required this.floor,
    required this.capacity,
    required this.fee,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      floor: json['floor'],
      capacity: json['capacity'],
      fee: (json['fee'] as num).toInt(),
    );
  }
}
