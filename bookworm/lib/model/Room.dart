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

  factory Room.fromMap(Map<String, dynamic> data) {
    return Room(
      id: data['id'] as String,
      name: data['name'] as String,
      floor: data['floor'] as String,
      capacity: data['capacity'] as int,
      fee: data['fee'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'floor': floor,
      'capacity': capacity,
      'fee': fee,
    };
  }
}
