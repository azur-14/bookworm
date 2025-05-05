class RoomBookingRequest {
  final String id;
  final String userId;
  final String roomId;
  final DateTime startTime;
  final DateTime endTime;
  String status; // 'pending', 'approved', 'rejected', 'cancelled'
  final String purpose;
  final DateTime requestTime;
  final double pricePerHour;  // thêm trường này

  RoomBookingRequest({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    this.status = 'pending',
    required this.purpose,
    required this.requestTime,
    required this.pricePerHour,  // bắt buộc truyền vào
  });

  factory RoomBookingRequest.fromJson(Map<String, dynamic> json) {
    return RoomBookingRequest(
      id: json['id'] as String,
      userId: json['user_id'] is Map ? json['user_id']['_id'] as String : json['user_id'] as String,
      roomId: json['room_id'] is Map ? json['room_id']['_id'] as String : json['room_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: json['status'] as String,
      purpose: json['purpose'] as String,
      requestTime: DateTime.parse(json['request_time'] as String),
      pricePerHour: (json['price_per_hour'] as num).toDouble(),  // parse giá
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'room_id': roomId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'purpose': purpose,
      'request_time': requestTime.toIso8601String(),
      'price_per_hour': pricePerHour,  // serialize giá
    };
  }
}
